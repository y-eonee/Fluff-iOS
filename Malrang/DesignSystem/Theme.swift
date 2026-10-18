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

/// 가구, 벽지, 바닥재의 색 이름. Asset Catalog 이름이거나 컬러 피커로 고른 "#RRGGBB"다.
enum Palette {
    static func uiColor(_ name: String) -> UIColor {
        guard name.hasPrefix("#"), let value = UInt32(name.dropFirst(), radix: 16) else {
            return UIColor(named: name) ?? .white
        }
        return UIColor(red: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                       blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }

    static func hex(_ color: Color) -> String {
        var (red, green, blue, alpha) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255 + 0.5), Int(green * 255 + 0.5), Int(blue * 255 + 0.5))
    }
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
