import SwiftUI

/// Figma's first affine row defines the gradient coordinate in normalized bounds.
struct RepresentativeGradientFill: View {
    let definition: RepresentativeGradient
    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1), height = max(proxy.size.height, 1)
            let row = definition.transform[0]
            let gx = row[0] / width, gy = row[1] / height
            let norm = max(gx * gx + gy * gy, .leastNonzeroMagnitude)
            let middle = row[0] / 2 + row[1] / 2 + row[2]
            let start = UnitPoint(x: 0.5 - middle * gx / norm / width, y: 0.5 - middle * gy / norm / height)
            let end = UnitPoint(x: start.x + gx / norm / width, y: start.y + gy / norm / height)
            LinearGradient(stops: definition.stops, startPoint: start, endPoint: end)
                .opacity(definition.opacity)
        }.allowsHitTesting(false)
    }
}

enum RepresentativeLayout {
    static let inset: CGFloat = 18
    static let cardRadius: CGFloat = 22
    static let actionRadius: CGFloat = 31.75
    static let actionHeight: CGFloat = 60
    // Verified in the newer flow: 1727:22363 and 1727:22562.
    static let disabledOpacity = 0.35
}

struct RepresentativeActionSurface: ViewModifier {
    var primary = true
    var height: CGFloat = RepresentativeLayout.actionHeight
    @Environment(\.isEnabled) private var enabled
    @Environment(\.updatedFlowDesign) private var updatedFlow
    @Environment(\.roomFlowDesign) private var roomFlow
    func body(content: Content) -> some View {
        content.pretendard(.medium, 16)
            .foregroundStyle(primary ? Color.rep4.c01 : Color.rep4.c25)
            .frame(maxWidth: .infinity, minHeight: height)
            .contentShape(RoundedRectangle(cornerRadius: RepresentativeLayout.actionRadius))
            .background {
                Group {
                    if primary {
                        if roomFlow { RoomFlowDesign.action }
                        else if updatedFlow { FlowDesign.action }
                        else { RepresentativeGradientFill(definition: RepresentativeGradients.cta) }
                    }
                    else { Color.rep4.c01 }
                }.clipShape(RoundedRectangle(cornerRadius: RepresentativeLayout.actionRadius))
            }
            .overlay {
                if !primary && !updatedFlow && !roomFlow {
                    RoundedRectangle(cornerRadius: RepresentativeLayout.actionRadius)
                        .strokeBorder(Color.rep4.c07.opacity(0.5))
                }
            }
            .opacity(enabled ? 1 : RepresentativeLayout.disabledOpacity)
    }
}

struct RepresentativeSelectionSurface: ViewModifier {
    let selected: Bool
    var radius: CGFloat = 14
    var neutral = Color.rep4.c01
    @Environment(\.updatedFlowDesign) private var updatedFlow
    @Environment(\.roomFlowDesign) private var roomFlow
    func body(content: Content) -> some View {
        content.background {
            Group {
                if selected {
                    if roomFlow { RepresentativeGradientFill(definition: RoomFlowDesign.selected) }
                    else if updatedFlow { FlowDesign.selected }
                    else { RepresentativeGradientFill(definition: RepresentativeGradients.selected) }
                }
                else { neutral }
            }.clipShape(RoundedRectangle(cornerRadius: radius))
        }.overlay {
            RoundedRectangle(cornerRadius: radius).strokeBorder(selected && !roomFlow ? (updatedFlow ? FlowDesign.selectionBorder : Color.rep4.c04) : .clear, lineWidth: 0.7)
        }
    }
}

struct RepresentativeHero<Content: View>: View {
    var showsGlow = false
    var compactGlow = false
    var flowGlow = "flow_making_glow"
    @Environment(\.updatedFlowDesign) private var updatedFlow
    @Environment(\.roomFlowDesign) private var roomFlow
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            Color.rep4.c01
            if showsGlow {
                GeometryReader { proxy in
                    if updatedFlow {
                        Image(compactGlow ? "flow_name_glow" : flowGlow).resizable().scaledToFit()
                            .frame(width: compactGlow ? 277.26 : 381.458)
                            .position(x: proxy.size.width / 2 - (compactGlow ? 3.15 : 3.65),
                                      y: proxy.size.height * (compactGlow ? 0.505 : 0.621))
                    } else {
                        Image("rep4_making_glow").resizable()
                            .frame(width: proxy.size.width * (compactGlow ? 0.830 : 1.139),
                                   height: proxy.size.height * (compactGlow ? 0.971 : 0.691))
                            .blur(radius: 21.674)
                            .position(x: proxy.size.width / 2 - (compactGlow ? 3.15 : 3.65),
                                      y: proxy.size.height * (compactGlow ? 0.553 : 0.621))
                    }
                }
            }
            content
        }.clipShape(RoundedRectangle(cornerRadius: RepresentativeLayout.cardRadius))
    }
}

#Preview {
    VStack {
        RepresentativeHero { Image("rep4_character_bear").resizable().scaledToFit().padding(20) }.frame(height: 383)
        Button("다음으로") {}.buttonStyle(CreationPrimaryButton())
    }.padding(18).background(Color.rep4.c11)
}

struct RepresentativeConfirmDialog: View {
    let title: String
    let message: String
    var verticalOffset: CGFloat = 0
    var leaveTitle = "나가기"
    var stayTitle = "머무르기"
    var outlinesSecondary = false
    let onLeave: () -> Void
    let onStay: () -> Void
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            Color.rep4.c03.opacity(0.3).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text(title).pretendard(.bold, 17, tracking: -0.85).frame(minHeight: 24.65)
                Text(message).pretendard(.regular, 14, tracking: -0.7).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: message.contains("\n") ? 40.6 : 20.3)
                HStack(spacing: 12) {
                    Button(leaveTitle, action: onLeave).modifier(RepresentativeActionSurface(primary: false, height: 44))
                        .overlay { if outlinesSecondary { Capsule().strokeBorder(Color(uiColor: Palette.uiColor("#EEEEEE")), lineWidth: 1).allowsHitTesting(false) } }
                    Button(stayTitle, action: onStay).modifier(RepresentativeActionSurface(primary: true, height: 44))
                }
            }.foregroundStyle(Color.rep4.c03).padding(25)
                .background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 22)).padding(.horizontal, 22)
                .compositingGroup()
                .shadow(color: Color(uiColor: Palette.uiColor("#4A6B63")).opacity(0.1), radius: 12, y: 8)
                .offset(y: verticalOffset + (geometry.safeAreaInsets.bottom - geometry.safeAreaInsets.top) / 2)
                .accessibilityAddTraits(.isModal)
        }.frame(width: geometry.size.width, height: geometry.size.height)
        }.accessibilityAction(.escape, onStay)
    }
}
