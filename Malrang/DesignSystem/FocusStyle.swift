import SwiftUI

/// Figma Cotton tokens, shared by all focus states.
enum FocusStyle {
    static let giftTop = Color(uiColor: Palette.uiColor("#F0E7EF"))
    static let giftBottom = Color(uiColor: Palette.uiColor("#FBF5E8"))
    static let canvas = Color.mib.bg.screen
    static let paper = Color.mib.bg.surface
    static let ink = Color.mib.text.primary
    static let muted = Color.mib.text.secondary
    static let line = Color.mib.line.default
    static let sage = Color.mib.action.primary
    static let shade = Color(uiColor: Palette.uiColor("#493D38"))
    static let inset: CGFloat = 24
    static let radius: CGFloat = 24
    static let buttonHeight: CGFloat = 60
    static let timerSize: CGFloat = 64
}

struct FocusPrimaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.pretendard(.bold, D1.ctaFontSize).foregroundStyle(Color.mib.text.onPrimary)
            .frame(maxWidth: .infinity, minHeight: FocusStyle.buttonHeight)
            .background(enabled ? Color.mib.action.primary : Color.mib.action.disabled, in: RoundedRectangle(cornerRadius: 30))
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
    static let value = Color(uiColor: Palette.uiColor("#5A89A8"))
    static let blue = Color(uiColor: Palette.uiColor("#CFE8F2"))
    static let yellow = Color(uiColor: Palette.uiColor("#FCEBC0"))
}
extension View {
    func creationOutline(fill: Color, radius: CGFloat) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.a.line, lineWidth: 1))
    }
}

struct CreationPrimaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.pretendard(.bold, D1.ctaFontSize, tracking: -0.32).foregroundStyle(Color.mib.text.onPrimary)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(enabled ? Color.mib.action.primary : Color.mib.action.disabled, in: RoundedRectangle(cornerRadius: 26))
    }
}

struct CreationSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.pretendard(.bold, D1.ctaFontSize).foregroundStyle(Color.mib.text.primary)
            .frame(maxWidth: .infinity, minHeight: 60).contentShape(Rectangle())
            .background(Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Color.mib.line.selected))
    }
}
