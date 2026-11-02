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
          try container.mainContext.save()
        }
        do {
          let container = try ModelContainer(
            for: Doll.self, RoomItem.self, DecorPhoto.self,
            configurations: ModelConfiguration(url: url))
          let dolls = try container.mainContext.fetch(FetchDescriptor<Doll>())
          checks["sleep_survives_reload"] = dolls.first?.restingBedID == bedID
          let frame = try container.mainContext.fetch(FetchDescriptor<RoomItem>()).first { $0.id == frameID }
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
      for item in room where item.kind.hasHomeInteraction && item.kind.blocksFloor {
        checks["blocked_placement_\(item.kind.rawValue)"] = !RoomLayout.canPlaceDoll(
          at: [item.x, item.z], in: room)
        checks["no_manual_seat_\(item.kind.rawValue)"] =
          RoomLayout.seat(at: [item.x, item.z], in: [item]).item == nil
      }
      if let chair = room.first(where: { $0.kind == .sofa }) {
        checks["lounge_chair_is_available"] =
          RoomLayout.seat(at: [chair.x, chair.z], in: room).item?.id == chair.id
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
          checks["sleep_head_towards_pillow_\(index)"] = simd_dot(heading, pillow) > 0.99
          checks["sleep_face_up_\(index)"] = face.y > 0.99
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
      checks["frame_photo_removal_restores_artwork"] = restoredFrame.findEntity(named: "custom-photo") == nil && restoredFrame.findEntity(named: "heart") != nil
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
      try? await Task.sleep(for: .milliseconds(100))
      checks["audio_timer_stops"] = !player.isPlaying && player.sound == nil
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
