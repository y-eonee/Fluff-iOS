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
  var tint: Color? = nil
  private var size: CGFloat { name == "back" ? 31.854 : name == "check" ? 16 : ["undo", "redo"].contains(name) ? 20 : ["study", "read", "task"].contains(name) ? 26 : 24 }
  private var assetName: String { name == "back" ? "rep4_edit_back" : "d1_\(name)" }
  var body: some View {
    Group {
      if let tint { Image(assetName).renderingMode(.template).resizable().foregroundStyle(tint) }
      else { Image(assetName).renderingMode(.original).resizable() }
    }.frame(width: size, height: size).accessibilityHidden(true)
  }
}

struct D1IconButton: View {
  let icon: String
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) { D1Icon(name: icon).frame(width: 44, height: 44)
      .background(icon == "back" ? Color.clear : Color.rep4.c01.opacity(0.74), in: Circle()) }
      .buttonStyle(.plain).accessibilityLabel(label)
  }
}

/// The creation screens share the same source arrow and navigation-bar inset.
struct CreationBackButton: View {
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      D1Icon(name: "back").offset(y: 5).frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }.buttonStyle(.plain).accessibilityLabel(label)
  }
}

/// The source keeps a 37 pt circle inside a 44 pt touch target.
struct RoomHistoryButton: View {
  let redo: Bool
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(redo ? "rep4_room_redo" : "rep4_room_undo").resizable().frame(width: 20, height: 20)
        .frame(width: 37, height: 37).background(Color.rep4.c02, in: Circle())
        .frame(width: 44, height: 44, alignment: .topLeading).contentShape(Rectangle())
    }.buttonStyle(RoomPressStyle()).accessibilityLabel(redo ? "다시하기" : "되돌리기")
  }
}

struct D1PrimaryStyle: ButtonStyle {
  @Environment(\.isEnabled) private var enabled
  func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(RepresentativeActionSurface(primary: true))
    }
}

struct D1SecondaryStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(RepresentativeActionSurface(primary: false))
    }
}

struct D1Choice: View {
  let title: String
  var selected = false
  var fillsWidth = false
  var height: CGFloat = 44
  var fontSize: CGFloat = 13
  var neutral: Color = Color.rep4.c11
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        if selected { D1Icon(name: "check").frame(width: 16, height: 16) }
        Text(title)
      }
      .pretendard(selected ? .medium : .regular, fontSize).padding(.horizontal, 12).frame(minHeight: height)
      .frame(maxWidth: fillsWidth ? .infinity : nil)
      .modifier(RepresentativeSelectionSurface(selected: selected, radius: 10, neutral: neutral))
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
