import SwiftUI

extension Color {
    enum app {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let inkSecondary = Color("inkSecondary")
        static let accent = Color("brandAccent")
        static let pastelYellow = Color("pastelYellow")
        static let pastelMint = Color("pastelMint")
        static let pastelSky = Color("pastelSky")
        static let danger = Color("danger")
    }
}

/// 가구, 벽지, 바닥재에 칠할 수 있는 색 (Asset Catalog 이름)
enum Palette {
    static let names = ["background", "surface", "pastelYellow", "pastelMint", "pastelSky", "brandAccent"]
}

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

enum Radius {
    static let small: CGFloat = 12
    static let card: CGFloat = 20
    static let large: CGFloat = 28
}

extension View {
    func cardStyle() -> some View {
        background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .shadow(color: Color.app.ink.opacity(0.08), radius: 12, y: 4)
    }
}
