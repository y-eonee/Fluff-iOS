import SwiftUI

/// Screen-space selection follows the projected 3D furniture as it moves.
struct FurnitureSelectionOverlay: View {
    let rect: CGRect
    let title: String
    var body: some View {
        RoundedRectangle(cornerRadius: 14).strokeBorder(Color.rep4.c03, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .overlay(alignment: .topLeading) {
                Text(title).pretendard(.bold, 12).foregroundStyle(Color.rep4.c01)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Color.rep4.c03, in: Capsule()).offset(y: -25)
            }.position(x: rect.midX, y: rect.midY).allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The wall highlight follows the four projected corners, including camera rotation.
struct WallSelectionOverlay: View {
    let points: [CGPoint]
    var body: some View {
        if let first = points.first {
            let outline = Path { path in
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
                path.closeSubpath()
            }
            outline.fill(Color.rep4.c03.opacity(0.18)).allowsHitTesting(false)
            outline.stroke(Color.rep4.c25, lineWidth: 2).allowsHitTesting(false)
            Text("왼쪽 벽").pretendard(.bold, 12).foregroundStyle(Color.white)
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(Color.rep4.c25, in: Capsule())
                .position(x: first.x + 34, y: first.y - 14)
                .allowsHitTesting(false)
        }
    }
}
