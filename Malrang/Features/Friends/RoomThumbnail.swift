import SwiftUI

/// 방 데이터로 그린 작은 방 그림. 3D 화면을 여러 개 띄우면 그려지지 않아서 2D로 그린다.
struct RoomThumbnail: View {
    let room: FriendRoom

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width / 2.3, size.height / 2.05)
            let origin = CGPoint(x: size.width / 2, y: size.height * 0.6)
            func project(_ x: Float, _ y: Float, _ z: Float) -> CGPoint {
                CGPoint(x: origin.x + CGFloat(x - z) * unit * 0.5,
                        y: origin.y + CGFloat(x + z) * unit * 0.27 - CGFloat(y) * unit * 0.62)
            }
            func polygon(_ points: [CGPoint], _ color: Color, shade: Double = 0) {
                var path = Path()
                path.addLines(points)
                path.closeSubpath()
                context.fill(path, with: .color(color))
                if shade > 0 { context.fill(path, with: .color(Color.app.ink.opacity(shade))) }
            }
            func color(_ item: RoomItemState) -> Color { Color(item.colorName ?? item.kind.defaultColorName) }

            if let floor = room.items.first(where: { $0.kind == .floor }) {
                polygon([project(-1, 0, -1), project(1, 0, -1), project(1, 0, 1), project(-1, 0, 1)], color(floor))
            }
            if let wall = room.items.first(where: { $0.kind == .wall }) {
                polygon([project(-1, 0, -1), project(-1, 1.4, -1), project(-1, 1.4, 1), project(-1, 0, 1)], color(wall), shade: 0.1)
                polygon([project(-1, 0, -1), project(-1, 1.4, -1), project(1, 1.4, -1), project(1, 0, -1)], color(wall))
            }
            let furniture = room.items.filter { $0.kind.isMovable }.sorted { $0.x + $0.z < $1.x + $1.z }
            for item in furniture {
                let half = SIMD2(item.kind.size.x, item.kind.size.z) / 2
                let (x0, x1, z0, z1) = (item.x - half.x, item.x + half.x, item.z - half.y, item.z + half.y)
                let top = item.kind.size.y
                polygon([project(x1, 0, z0), project(x1, top, z0), project(x1, top, z1), project(x1, 0, z1)], color(item), shade: 0.12)
                polygon([project(x0, 0, z1), project(x0, top, z1), project(x1, top, z1), project(x1, 0, z1)], color(item), shade: 0.06)
                polygon([project(x0, top, z0), project(x1, top, z0), project(x1, top, z1), project(x0, top, z1)], color(item))
            }
            for doll in room.dolls {
                let point = project(doll.position.x, doll.position.y + 0.2, doll.position.z)
                let radius = unit * 0.075
                context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                             with: .color(Color.app.accent))
                context.stroke(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                               with: .color(Color.app.surface), lineWidth: 1.5)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    RoomThumbnail(room: FriendRoom(items: RoomItem.starterRoom.map(\.state),
                                   dolls: [DollState(id: UUID(), name: "", imageData: Data(), filling: .fluffy, position: [0, 0, 0.5], dance: nil)]))
        .frame(width: 96, height: 80)
        .background(Color.app.background)
}
