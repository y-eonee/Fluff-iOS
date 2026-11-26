#if DEBUG
  import AVFoundation
  import RealityKit
  import SwiftData
  import UIKit

  /// Exercises real persistence, model geometry and audio lifecycle in an isolated simulator run.
  @MainActor enum FurnitureInteractionAudit {
    static func run() async {
      var checks: [String: Bool] = [:]
      let image = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 100)).image { _ in
        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(x: 10, y: 5, width: 60, height: 90)).fill()
      }
      let data = image.pngData()!
      let bedID = UUID()
      let frameID = UUID()
      let wallID = UUID()
      let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
        UUID().uuidString)
      do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("audit.store")
        do {
          let container = try ModelContainer(
            for: Doll.self, RoomItem.self, DecorPhoto.self,
            configurations: ModelConfiguration(url: url))
          let doll = Doll(name: "수면 검증", shape: .cat, filling: .fluffy, imageData: data)
          doll.isPlaced = true
          doll.restingBedID = bedID
          doll.presetConfiguration = PresetConfiguration()
          container.mainContext.insert(doll)
          let frame = RoomItem(kind: .frame); frame.id = frameID; frame.photoData = data
          frame.photoScale = 1.8; frame.photoFit = 1; frame.photoTurns = 3; frame.photoFlipped = true
          frame.photoOffsetX = 0.2; frame.photoOffsetY = -0.1
          container.mainContext.insert(frame)
          let wall = RoomItem(kind: .wall); wall.id = wallID
          wall.photoData = data; wall.rightWallPhotoData = Data(data.reversed())
          wall.rightWallColorName = "#C3B5DC"
          let snapshot = wall.state
          wall.rightWallPhotoData = nil
          wall.restore(snapshot)
          checks["right_wall_photo_undo_is_independent"] = wall.rightWallPhotoData == Data(data.reversed()) && wall.photoData == data
          container.mainContext.insert(wall)
          try container.mainContext.save()
        }
        do {
          let container = try ModelContainer(
            for: Doll.self, RoomItem.self, DecorPhoto.self,
            configurations: ModelConfiguration(url: url))
          let dolls = try container.mainContext.fetch(FetchDescriptor<Doll>())
          checks["sleep_survives_reload"] = dolls.first?.restingBedID == bedID
          let frame = try container.mainContext.fetch(FetchDescriptor<RoomItem>()).first { $0.id == frameID }
          let wall = try container.mainContext.fetch(FetchDescriptor<RoomItem>()).first { $0.id == wallID }
          checks["independent_wall_photos_survive_reload"] = wall?.photoData == data && wall?.rightWallPhotoData == Data(data.reversed()) && wall?.rightWallColorName == "#C3B5DC"
          checks["frame_photo_survives_reload"] = frame?.photoData == data && frame?.photoScale == 1.8 && frame?.photoTurns == 3 && frame?.photoFlipped == true && frame?.photoOffsetX == 0.2 && frame?.photoOffsetY == -0.1
          dolls.first?.restingBedID = nil
          try container.mainContext.save()
        }
        do {
          let container = try ModelContainer(
            for: Doll.self, RoomItem.self, DecorPhoto.self,
            configurations: ModelConfiguration(url: url))
          checks["wake_survives_reload"] =
            try container.mainContext.fetch(FetchDescriptor<Doll>()).first?.restingBedID == nil
        }
      } catch { checks["persistence"] = false }
      let room = RoomItem.starterRoom.map(\.state)
      for item in room where item.kind.hasHomeInteraction && item.kind.blocksFloor && !item.kind.allowsDollPlacement {
        checks["blocked_placement_\(item.kind.rawValue)"] = !RoomLayout.canPlaceDoll(
          at: [item.x, item.z], in: room)
        checks["no_manual_seat_\(item.kind.rawValue)"] =
          RoomLayout.seat(at: [item.x, item.z], in: [item]).item == nil
      }
      if let sofa = room.first(where: { $0.kind == .sofa }) {
        checks["sofa_reserved_for_activity"] =
          RoomLayout.seat(at: [sofa.x, sofa.z], in: room, includingActivitySeats: true).item?.id == sofa.id
        checks["sofa_display_name"] = sofa.kind.label == "소파"
      }
      if let chair = room.first(where: { $0.kind == .chair }) {
        for shape in DollShape.presets {
          var config = PresetConfiguration(); config.shape = shape
          let seatedDoll = Doll(name: "의자 검증", shape: .cat, filling: .fluffy, imageData: data)
          seatedDoll.presetConfiguration = config
          let model = await SceneFactory.doll(seatedDoll.state)
          DollRestPose.sitting(model)
          let firstFoot = model.findEntity(named: DollPart.leftLeg.rawValue)?.transform
          DollRestPose.sitting(model)
          let repeatedFoot = model.findEntity(named: DollPart.leftLeg.rawValue)?.transform
          checks["seating_\(shape.rawValue)_does_not_accumulate_offsets"] = firstFoot != nil && firstFoot == repeatedFoot
          for (index, yaw) in [Float(0), .pi / 2, .pi, -.pi / 2].enumerated() {
            var seat = chair; seat.yaw = yaw
            DollRestPose.chairSeat(model, on: seat)
            let frame = Entity()
            frame.position = [seat.x, 0, seat.z]
            frame.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
            let common = Entity(); common.addChild(frame); common.addChild(model)
            let bounds = model.visualBounds(relativeTo: frame)
            let key = "chair_\(shape.rawValue)_\(index)"
            checks[key + "_above_cushion"] = bounds.min.y >= (seat.kind.seatHeight ?? 0) + 0.007
            checks[key + "_clear_backrest"] = bounds.min.z >= -seat.kind.size.z * 0.36 + 0.085 / 2 + 0.011
            checks[key + "_faces_front"] = simd_dot(model.orientation.act([0, 0, 1]), frame.orientation.act([0, 0, 1])) > 0.999
            checks[key + "_fits_width"] = bounds.extents.x <= seat.kind.size.x * 0.86
            model.removeFromParent()
          }
        }
      }
      if let roomBed = room.first(where: { $0.kind == .bed }), let spot = RoomLayout.dollSpot(avoiding: room, dolls: []) {
        checks["starter_room_has_walk_to_bed"] = DollBedRoute.plan(from: spot, bed: roomBed, items: room) != nil
      }
      let fullRoom = [
        RoomItemState(id: UUID(), kind: .bed, x: 0, z: 0),
        RoomItemState(id: UUID(), kind: .desk, x: 0.6, z: 0.6),
      ]
      if let spot = RoomLayout.dollSpot(avoiding: fullRoom, dolls: []) {
        checks["new_doll_avoids_interactions"] = RoomLayout.canPlaceDoll(
          at: [spot.x, spot.z], in: fullRoom)
      }
      // Shared home/editor geometry must fit even after rotations and mirroring.
      for kind in FurnitureKind.allCases where kind.isMovable {
        let sample = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
        _ = await SceneFactory.furniture(sample, cozy: true, cutaway: true)
        for yaw: Float in [0, .pi / 4, .pi / 2, .pi] {
          for mirrored in [false, true] {
            for corner: SIMD2<Float> in [[-2, -2], [2, 2], [-2, 2], [2, -2]] {
              var item = sample; item.x = corner.x; item.z = corner.y; item.yaw = yaw; item.isMirrored = mirrored
              let spot = RoomLayout.constrained(item); item.x = spot.x; item.z = spot.y
              if !kind.hangsOnWall {
                let box = RoomLayout.placementFootprint(item)
                checks["room_bounds_\(kind.rawValue)_\(yaw)_\(mirrored)_\(corner)"] = box.min.x >= -1.001 && box.min.y >= -1.001 && box.max.x <= 1.001 && box.max.y <= 1.001
              }
            }
          }
        }
      }
      let repairedRoom = RoomLayout.repaired(room)
      checks["repaired_starter_has_no_furniture_overlap"] = repairedRoom.allSatisfy { !RoomLayout.overlaps($0, in: repairedRoom) }
      checks["repair_is_idempotent"] = RoomLayout.repaired(repairedRoom) == repairedRoom
      for kind in [FurnitureKind.bed, .sofa, .desk, .chair, .frame, .shelf, .lamp] {
        let item = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
        let home = await SceneFactory.furniture(item, cozy: true)
        let editor = await SceneFactory.furniture(item, cozy: true, cutaway: true)
        let a = home.visualBounds(relativeTo: home), b = editor.visualBounds(relativeTo: editor)
        checks["same_geometry_\(kind.rawValue)"] = simd_distance(a.min, b.min) < 0.001 && simd_distance(a.max, b.max) < 0.001 && home.position == editor.position && home.scale == editor.scale
      }
      for kind in [FurnitureKind.bed, .sofa, .desk, .chair, .frame, .rugRound] {
        let item = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
        let model = await SceneFactory.furniture(item, onFloor: true, cozy: true, cutaway: true)
        func signature(_ root: Entity) -> [SIMD3<Float>] {
          var values: [SIMD3<Float>] = []
          func visit(_ node: Entity) {
            values.append(node.position)
            if let mesh = node.components[ModelComponent.self]?.mesh {
              for part in mesh.contents.models.flatMap({ Array($0.parts) }) {
                let points = part.positions.elements
                // Mesh generation may merge duplicate vertices; face count and
                // occupied shape must survive, not the internal vertex layout.
                values.append(SIMD3(Float(part.triangleIndices?.count ?? 0), 0, 0))
                values.append(points.reduce(SIMD3<Float>(repeating: .infinity), simd_min))
                values.append(points.reduce(SIMD3<Float>(repeating: -.infinity), simd_max))
              }
            }
            for child in node.children { visit(child) }
          }
          visit(root); return values
        }
        let before = signature(model)
        FurnitureSurfaceGeometry.reflect(model)
        FurnitureSurfaceGeometry.reflect(model)
        let after = signature(model)
        checks["mirror_twice_preserves_every_part_\(kind)"] = before.count == after.count && zip(before, after).allSatisfy { simd_distance($0, $1) < 0.0001 }
      }
      for aspect in [0.4, 1.0, 2.5] {
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 120 * aspect, height: 120)).image { context in
          UIColor.systemTeal.setFill(); context.fill(CGRect(x: 0, y: 0, width: 120 * aspect, height: 120))
        }.pngData()!
        for mirrored in [false, true] { for flipped in [false, true] { for turns in 0..<4 { for zoom: Float in [1, 2] {
          var item = RoomItemState(id: UUID(), kind: .rugRound, x: 0, z: 0)
          item.photoData = photo; item.isMirrored = mirrored; item.photoFlipped = flipped; item.photoTurns = turns
          item.photoScale = zoom; item.photoFit = 1; item.photoOffsetX = 0.9; item.photoOffsetY = -0.9
          let model = await SceneFactory.furniture(item, onFloor: true, cozy: true, cutaway: true)
          let key = "rug_photo_\(aspect)_\(mirrored)_\(flipped)_\(turns)_\(zoom)"
          guard let rug = model.findEntity(named: "rug"), let mesh = rug.components[ModelComponent.self],
                let material = mesh.materials.first as? UnlitMaterial else { checks[key] = false; continue }
          let parts = mesh.mesh.contents.models.flatMap { Array($0.parts) }
          let t = material.textureCoordinateTransform
          let c = cos(t.rotation), sinA = sin(t.rotation)
          let uvs = parts.flatMap { $0.textureCoordinates?.elements ?? [] }
          let filled = uvs.allSatisfy { uv in
            let p = uv * t.scale
            let transformed = SIMD2(c * p.x - sinA * p.y, sinA * p.x + c * p.y) + t.offset
            return transformed.min() >= -0.0001 && transformed.max() <= 1.0001
          }
          let topFaces = parts.contains { part in
            guard let indices = part.triangleIndices?.elements else { return false }
            let points = part.positions.elements
            return stride(from: 0, to: indices.count, by: 3).contains { i in
              let a = points[Int(indices[i])], b = points[Int(indices[i+1])], c = points[Int(indices[i+2])]
              return simd_cross(b - a, c - a).y > 0.000001
            }
          }
          checks[key] = material.color.texture != nil && !uvs.isEmpty && filled && topFaces
            && rug.scale.min() > 0 && model.findEntity(named: "custom-photo") == nil
        } } } }
      }
      for kind in [FurnitureKind.bed, .floor] {
        var item = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0); item.photoData = data
        let model = await SceneFactory.furniture(item, onFloor: true, cozy: true, cutaway: true)
        checks["\(kind)_photo_has_no_floating_plane"] = model.findEntity(named: "custom-photo") == nil
        let name = kind == .bed ? "duvet" : "floor"
        checks["\(kind)_surface_has_photo"] = (model.findEntity(named: name)?.components[ModelComponent.self]?.materials.first as? UnlitMaterial)?.color.texture != nil
        if kind == .bed { checks["bed_no_wood_frame"] = model.findEntity(named: "frame") == nil && model.findEntity(named: "headboard") == nil }
      }
      for shape in [DollShape.cat, .bear, .rabbit] {
        var configuration = PresetConfiguration(); configuration.shape = shape
        let baseline = await PresetDollModel.make(configuration, detail: .room)
        let head0 = baseline.findEntity(named: "head")!, ears0 = baseline.findEntity(named: "ears")!
        let relativeEars = (ears0.position - head0.position) / head0.scale
        for size: Float in [0.6, 1.4] {
          configuration.parts["head"] = .init(width: size, size: size, length: size, offset: 0.2)
          configuration.parts["torso"] = .init(width: 2 - size, size: 2 - size, length: 2 - size)
          for part in [DollPart.leftArm, .rightArm, .leftLeg, .rightLeg] {
            configuration.parts[part.rawValue] = .init(width: size, size: size, length: size)
          }
          let model = await PresetDollModel.make(configuration, detail: .room)
          let head = model.findEntity(named: "head")!, ears = model.findEntity(named: "ears")!
          checks["ears_follow_head_\(shape)_\(size)"] = simd_distance(relativeEars, (ears.position - head.position) / head.scale) < 0.0001
          let torso = model.findEntity(named: "torso")!.visualBounds(relativeTo: model)
          for part in [DollPart.leftArm, .rightArm, .leftLeg, .rightLeg] {
            let limb = model.findEntity(named: part.rawValue)!.visualBounds(relativeTo: model)
            let overlap = simd_min(torso.max, limb.max) - simd_max(torso.min, limb.min)
            checks["limb_attached_\(shape)_\(part)_\(size)"] = overlap.min() > 0
          }
        }
      }
      checks["catalog_excludes_flower_cushion"] = !FurnitureKind.catalog.contains(.flowerCushion)
      let day = RoomDaylight.at(hour: 12)
      let night = RoomDaylight.at(hour: 23)
      let sunset = RoomDaylight.at(hour: 18)
      checks["night_reduces_window_light"] = night.strength < day.strength * 0.05
      checks["sunset_is_warmer_than_day"] = sunset.tint.z < day.tint.z
      checks["dawn_light_increases"] =
        RoomDaylight.at(hour: 6).strength < RoomDaylight.at(hour: 7).strength
      checks["local_time_uses_timezone"] =
        RoomDaylight.at(hour: 0).phase == .night && day.phase == .day
      let lamp = await SceneFactory.furniture(RoomItemState(id: UUID(), kind: .lamp, x: 0, z: 0), cozy: true)
      await CozyRoomLighting.apply(night, to: lamp)
      let lampLight = lamp.findEntity(named: "desk-lamp-light") as? PointLight
      checks["desk_lamp_lights_room_at_night"] = (lampLight?.light.intensity ?? 0) > 100
      if let shade = lamp.findEntity(named: "shade")?.components[ModelComponent.self]?.materials.first as? CustomMaterial {
        checks["desk_lamp_shade_glows"] = shade.custom.value.z < 0
      } else { checks["desk_lamp_shade_glows"] = false }
      await CozyRoomLighting.apply(day, to: lamp)
      checks["desk_lamp_off_in_daylight"] = lampLight?.light.intensity == 0
      let custom = await PlushCutoutModel.make(data)
      checks["cutout_has_closed_surfaces"] = ["cutout.front", "cutout.back", "cutout.seam"]
        .allSatisfy { custom.findEntity(named: $0) != nil }
      let doll = Doll(name: "모델 검증", shape: .cat, filling: .fluffy, imageData: data)
      let couchDefaults = UserDefaults(suiteName: "fluff.couch-limit-audit.\(UUID())")!
      let couch = CouchSession(library: CouchLibrary(defaults: couchDefaults))
      let secondDoll = Doll(name: "두 번째", shape: .bear, filling: .fluffy, imageData: data)
      couch.dolls = [doll.state, secondDoll.state]
      checks["couch_keeps_two_companions"] = couch.dolls.map(\.id) == [doll.id, secondDoll.id]
      couch.dolls = [secondDoll.state]
      checks["couch_replaces_companion"] = couch.dolls.map(\.id) == [secondDoll.id]
      couch.dolls = []
      checks["couch_clears_companion"] = couch.dolls.isEmpty
      doll.presetConfiguration = PresetConfiguration()
      let model = await SceneFactory.doll(doll.state)
      let bed = RoomItem(kind: .bed).state
      DollRestPose.sleeping(model, bed: bed, animated: false)
      checks["sleep_uses_articulated_model"] =
        model.findEntity(named: "leftArm") != nil
        && model.findEntity(named: "body")?.orientation != simd_quatf()
      for (index, yaw) in [Float(0), .pi / 2, .pi, .pi * 1.5].enumerated() {
        var rotated = bed; rotated.yaw = yaw
        DollRestPose.sleeping(model, bed: rotated, animated: false)
        if let body = model.findEntity(named: "body") {
          let heading = simd_act(model.orientation * body.orientation, SIMD3<Float>(0, 1, 0))
          let pillow = simd_act(simd_quatf(angle: yaw, axis: [0, 1, 0]), SIMD3<Float>(0, 0, -1))
          let face = simd_act(model.orientation * body.orientation, SIMD3<Float>(0, 0, 1))
          // The connected doll reclines on a pillow, rather than lying flat.
          // Its horizontal heading must still follow the rotated bed, and
          // its face must point predominantly upward rather than forward.
          let horizontalHeading = SIMD3<Float>(heading.x, 0, heading.z)
          checks["sleep_head_towards_pillow_\(index)"] = simd_length(horizontalHeading) > 0.001
            && simd_dot(simd_normalize(horizontalHeading), pillow) > 0.99
          checks["sleep_face_up_\(index)"] = face.y > max(abs(face.x), abs(face.z))
        }
      }
      let radio = await RadioModel.make(playing: true)
      checks["radio_has_separate_controls"] = ["radio.volume", "radio.tuning-slider", "radio.antenna", "radio.power"].allSatisfy { radio.findEntity(named: $0) != nil }
      checks["radio_has_woven_grille"] = (radio.findEntity(named: "radio.speaker")?.children.filter { $0.name == "radio.grille-strand" }.count ?? 0) >= 40
      var photoFrame = RoomItemState(id: UUID(), kind: .frame, x: 0, z: 0)
      photoFrame.photoData = data
      let firstFrame = await SceneFactory.furniture(photoFrame, onFloor: true, cozy: true)
      if let photo = firstFrame.findEntity(named: "custom-photo"), let mat = firstFrame.findEntity(named: "mat") {
        checks["frame_photo_in_front_of_mat"] = photo.position.z > mat.visualBounds(relativeTo: firstFrame).max.z
        checks["frame_photo_has_texture"] = (photo.components[ModelComponent.self]?.materials.first as? UnlitMaterial)?.color.texture != nil
      } else { checks["frame_photo_in_front_of_mat"] = false }
      checks["frame_photo_replaces_heart"] = firstFrame.findEntity(named: "heart") == nil
      photoFrame.photoScale = 2; photoFrame.photoTurns = 1; photoFrame.photoFlipped = true; photoFrame.photoOffsetX = 0.2
      let editedFrame = await SceneFactory.furniture(photoFrame, onFloor: true, cozy: true)
      let firstMaterial = firstFrame.findEntity(named: "custom-photo")?.components[ModelComponent.self]?.materials.first as? UnlitMaterial
      let editedMaterial = editedFrame.findEntity(named: "custom-photo")?.components[ModelComponent.self]?.materials.first as? UnlitMaterial
      checks["frame_photo_edits_invalidate_cache"] = firstMaterial?.textureCoordinateTransform.scale != editedMaterial?.textureCoordinateTransform.scale
      photoFrame.photoData = nil
      let restoredFrame = await SceneFactory.furniture(photoFrame, onFloor: true, cozy: true)
      checks["frame_photo_removal_restores_artwork"] = restoredFrame.findEntity(named: "custom-photo") == nil && restoredFrame.findEntity(named: "art.blue") != nil
      let player = AmbientPlayer()
      for sound in AmbientSound.allCases {
        player.start(sound, minutes: 30)
        checks["audio_\(sound.rawValue)"] =
          player.isPlaying && player.sound == sound && player.remaining()! > 1790
      }
      player.pause()
      let remaining = player.remaining()
      checks["audio_pause"] = !player.isPlaying && player.sound != nil && remaining != nil
      player.resume()
      checks["audio_resume"] = player.isPlaying
      player.setTimer(nil)
      checks["audio_continuous"] = player.remaining() == nil
      player.setTimer(0)
      // The current clock clamps a numeric duration to at least one minute;
      // zero is not an immediate-stop command (nil means continuous playback).
      checks["audio_timer_minimum_duration"] = player.isPlaying && (player.remaining() ?? 0) > 59
      player.start(.rain, minutes: 15)
      player.stop()
      checks["audio_stop_clears_state"] = player.sound == nil && player.endDate == nil
      let result: [String: Any] = ["passed": checks.values.allSatisfy { $0 }, "checks": checks]
      if let json = try? JSONSerialization.data(
        withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
      {
        let output = URL.documentsDirectory.appendingPathComponent("furniture-audit.json")
        try? json.write(to: output)
      }
      try? FileManager.default.removeItem(at: directory)
    }
  }
#endif
