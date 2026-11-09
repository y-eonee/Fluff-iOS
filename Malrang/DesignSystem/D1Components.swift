import SwiftUI

/// DESIGN.md Components and the supplied D1 catalog. No independent UI palette.
enum D1 {
  static let ctaFontSize: CGFloat = 16
  static let inset: CGFloat = 22
  static let radius: CGFloat = 14
  static let largeRadius: CGFloat = 22
  static let buttonHeight: CGFloat = 60
}

struct D1Icon: View {
  let name: String
  private var size: CGFloat { name == "check" ? 16 : ["undo", "redo"].contains(name) ? 20 : ["study", "read", "task"].contains(name) ? 26 : 24 }
  var body: some View {
    Image("d1_\(name)").renderingMode(.original).resizable().frame(
      width: size, height: size
    ).accessibilityHidden(true)
  }
}

struct D1IconButton: View {
  let icon: String
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) { D1Icon(name: icon).frame(width: 44, height: 44).d1Surface(radius: 22) }
      .buttonStyle(.plain).accessibilityLabel(label)
  }
}

struct D1PrimaryStyle: ButtonStyle {
  @Environment(\.isEnabled) private var enabled
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.pretendard(.bold, D1.ctaFontSize)
      .foregroundStyle(Color.mib.text.onPrimary)
      .frame(maxWidth: .infinity, minHeight: D1.buttonHeight)
      .contentShape(Rectangle())
      .background(enabled ? Color.mib.action.primary : Color.mib.action.disabled, in: Capsule())
  }
}

struct D1SecondaryStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.pretendard(.bold, D1.ctaFontSize).foregroundStyle(Color.mib.text.primary)
      .frame(maxWidth: .infinity, minHeight: D1.buttonHeight)
      .contentShape(Rectangle())
      .background(Color.mib.bg.surface, in: Capsule())
      .overlay(Capsule().strokeBorder(Color.mib.line.selected, lineWidth: 1.4))
  }
}

struct D1Choice: View {
  let title: String
  var selected = false
  var fillsWidth = false
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        if selected { D1Icon(name: "check").frame(width: 16, height: 16) }
        Text(title)
      }
      .pretendard(.medium, 13).padding(.horizontal, 12).frame(minHeight: 44)
      .frame(maxWidth: fillsWidth ? .infinity : nil)
      .background(
        selected ? Color.mib.bg.mintSoft : Color.mib.bg.surface,
        in: RoundedRectangle(cornerRadius: 10)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10).strokeBorder(
          selected ? Color.mib.line.selected : Color.mib.line.default, lineWidth: 2))
    }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
  }
}

struct D1Bubble: View {
  let text: String
  var body: some View {
    Text(text).pretendard(.medium, 13).multilineTextAlignment(.center)
      .padding(.horizontal, 12).frame(minHeight: 44).d1Surface(radius: 22)
  }
}

extension View {
  func d1Surface(radius: CGFloat = D1.radius) -> some View {
    background(Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: radius))
      .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Color.mib.line.default))
      .foregroundStyle(Color.mib.text.primary)
  }
}

struct D1HomeTabs: View {
  @Binding var selection: AppTab
  private let items: [(AppTab, String, String)] = [
    (.dolls, "인형들", "cloud"), (.home, "내 방", "homeTab"),
    (.mypage, "마이", "my"),
  ]
  var body: some View {
    HStack(spacing: 8) {
      ForEach(items, id: \.0) { tab, title, icon in
        Button {
          selection = tab
        } label: {
          VStack(spacing: 4) {
            D1Icon(name: icon)
            Text(title).pretendard(.bold, 12)
          }
          .frame(maxWidth: .infinity).frame(height: 64)
          .background(
            selection == tab ? Color.mib.bg.mintSoft : Color.mib.bg.surface,
            in: RoundedRectangle(cornerRadius: 10)
          )
          .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.mib.line.default))
        }.buttonStyle(.plain).accessibilityAddTraits(selection == tab ? .isSelected : [])
      }
    }.foregroundStyle(Color.mib.text.primary).padding(.horizontal, 22).padding(.vertical, 8)
      .background(Color.mib.bg.surface.opacity(0.9).ignoresSafeArea(edges: .bottom))
  }
}

extension View {
  /// DESIGN.md image-surface recipe: translucent ivory, material blur and inner highlight.
  func d1ImageSurface(radius: CGFloat = 20) -> some View {
    background {
      RoundedRectangle(cornerRadius: radius).fill(Color.mib.bg.surface.opacity(0.60))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
    }
    .overlay(
      RoundedRectangle(cornerRadius: radius).strokeBorder(
        Color.mib.text.onPrimary.opacity(0.70), lineWidth: 1)
    )
    .foregroundStyle(Color.mib.text.primary)
  }
}
