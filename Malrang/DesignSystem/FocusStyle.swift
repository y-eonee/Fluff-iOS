import SwiftUI

/// Figma Cotton tokens, shared by all focus states.
enum FocusStyle {
    static let canvas = Color(uiColor: Palette.uiColor("#FBF9F5"))
    static let paper = Color(uiColor: Palette.uiColor("#FFFCF8"))
    static let ink = Color(uiColor: Palette.uiColor("#674D42"))
    static let muted = Color(uiColor: Palette.uiColor("#947F73"))
    static let line = Color(uiColor: Palette.uiColor("#E9DFD7"))
    static let sage = Color(uiColor: Palette.uiColor("#A8B59A"))
    static let shade = Color(uiColor: Palette.uiColor("#493D38"))
    static let inset: CGFloat = 24
    static let radius: CGFloat = 24
    static let buttonHeight: CGFloat = 56
    static let timerSize: CGFloat = 64
}

struct FocusPrimaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(enabled ? .white : FocusStyle.muted)
            .frame(maxWidth: .infinity, minHeight: FocusStyle.buttonHeight)
            .background(enabled ? FocusStyle.ink : FocusStyle.line, in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Viewports match the original Figma component crops; source atlases remain unmodified.
struct CottonArtwork: View {
    enum Pose { case idle, working, workingAlternate, happy, flower, bench }
    var shape: DollShape = .cat
    var pose: Pose = .idle
    var body: some View {
        GeometryReader { proxy in
            if pose == .flower || pose == .bench || shape == .cat {
                let rect = crop
                let scale = proxy.size.width / rect.width
                Image("focus_cat_atlas").resizable()
                    .frame(width: 480 * scale, height: 720 * scale)
                    .offset(x: -rect.minX * scale, y: -rect.minY * scale)
            } else {
                Image("focus_presets").resizable().scaledToFit()
                    .frame(width: proxy.size.width * 2, height: proxy.size.height)
                    .offset(x: shape == .rabbit ? -proxy.size.width : 0)
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipped()
        .accessibilityHidden(true)
    }
    private var crop: CGRect {
        switch pose {
        case .working: CGRect(x: 0, y: 0, width: 240, height: 258.75)
        case .workingAlternate: CGRect(x: 240, y: 0, width: 240, height: 258.75)
        case .idle: CGRect(x: 0, y: 262.5, width: 240, height: 253.125)
        case .happy: CGRect(x: 240, y: 262.5, width: 240, height: 253.125)
        case .flower: CGRect(x: 0, y: 515.625, width: 240, height: 204.375)
        case .bench: CGRect(x: 240, y: 515.625, width: 240, height: 204.375)
        }
    }
    private var aspect: CGFloat { shape == .cat || pose == .flower || pose == .bench ? crop.width / crop.height : 88 / 92.8 }
}

enum CreationStyle {
    static let blue = Color(uiColor: Palette.uiColor("#CFE7EE"))
    static let yellow = Color(uiColor: Palette.uiColor("#FFF0BE"))
}
extension View {
    func creationOutline(fill: Color, radius: CGFloat) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.a.line, lineWidth: 1))
    }
}
