import SwiftUI

/// Source 1918:7551 (cotton) / 1904:6831 (owned doll). One source clock
/// coordinates the veil, character, copy and progress before revealing the live room.
struct RoomLoadingView: View {
    let entrance: RoomEntrance
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let ink = Color(uiColor: Palette.uiColor("#614A40"))
    static let veil = RepresentativeGradient(
        stops: [.init(color: Color(.sRGB, red: 0.9974356294, green: 0.9974356294, blue: 0.9974356294), location: 0),
                .init(color: Color(.sRGB, red: 0.8878208995, green: 0.9736048579, blue: 1), location: 0.9697805643)],
        transform: [[0.03376460448, 0.63030683994, 0.50053244829], [-0.63030683994, 0.00415693317, 0.92314726114]], opacity: 1)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: scenePhase != .active || entrance.finished)) { _ in
            let cotton = entrance.loadingDoll == nil
            let time = entrance.time
            GeometryReader { geometry in
                let scale = min(geometry.size.width / 390, geometry.size.height / 844)
                ZStack {
                    RepresentativeGradientFill(definition: Self.veil)
                        .opacity(entrance.presentsSceneDoll ? 0 : value(cotton ? "1932:6465" : "1904:6845", "opacity", time, 1))
                    ZStack(alignment: .topLeading) {
                        if let doll = entrance.loadingDoll {
                            if !entrance.presentsSceneDoll { ownedDoll(doll, time: time) }
                        } else {
                            CottonLoadingCharacter(time: reduceMotion ? 0 : time)
                                .modifier(RoomEntranceMotion(entrance: entrance, node: "1918:7552"))
                                .offset(x: 116, y: 282)
                        }
                        message("인형들을 깨우고 있어요.", node: cotton ? "1932:6469" : "1904:6856", y: cotton ? 566 : 478)
                        message("이불을 폭신하게 펴는 중…", node: cotton ? "1932:6485" : "1904:6882", y: cotton ? 566 : 478)
                        message("포근한 방 완성!", node: cotton ? "1932:6497" : "1904:6893", y: cotton ? 566 : 478)
                        Capsule().fill(.white).frame(width: 305.38, height: 6)
                            .overlay(alignment: .leading) {
                                Capsule().fill(Color(uiColor: Palette.uiColor("#76D9F9")))
                                    .frame(width: value(cotton ? "1932:6510" : "1912:7244", "width", time, 6) * (cotton ? 1 : 390 / 334.831), height: 6)
                            }
                            .scaleEffect(x: 1, y: value(cotton ? "1932:6509" : "1912:7236", "--motion-scale-y", time, 1))
                            .opacity(value(cotton ? "1932:6508" : "1912:7235", "opacity", time, 1))
                            .offset(x: 39.6, y: 607)
                        Text("잠시만 기다려 주세요.").pretendard(.medium, 14)
                            .foregroundStyle(ink.opacity(0.55)).frame(width: 390)
                            .opacity(value(cotton ? "1932:6481" : "1904:6871", "opacity", time, 1))
                            .offset(y: 642.63)
                    }.frame(width: 390, height: 844, alignment: .topLeading)
                        .scaleEffect(scale)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("인형들을 깨우고 있어요. 잠시만 기다려 주세요.")
            .accessibilityValue(entrance.loadingDoll?.name ?? "솜뭉치")
            .accessibilityIdentifier("room-loading")
        }.ignoresSafeArea().contentShape(Rectangle())
    }

    private func value(_ node: String, _ property: String, _ time: Double, _ fallback: Double) -> Double {
        entrance.timeline.value(node, property, at: time, fallback: fallback)
    }
    private func message(_ text: String, node: String, y: Double) -> some View {
        Text(text).pretendard(.semiBold, 16).foregroundStyle(Color.rep4.c03).frame(width: 390)
            .modifier(RoomEntranceMotion(entrance: entrance, node: node, spatialScale: entrance.loadingDoll == nil ? 1 : 390 / 334.831)).offset(y: y)
    }
    private func ownedDoll(_ doll: DollState, time: Double) -> some View {
        let ratio = 390 / 334.831
        return Group {
            if let preset = doll.preset {
                PresetDollView(configuration: preset, fitsModel: true, fitMargin: 1, animating: !reduceMotion)
                    .allowsHitTesting(false)
            } else { DollThumbnail(data: doll.imageData).scaledToFit() }
        }
        .frame(width: 168.274 * ratio, height: 231.806 * ratio)
        .scaleEffect(0.5)
        .frame(width: 84.137 * ratio, height: 115.903 * ratio)
        .shadow(color: Color(uiColor: Palette.uiColor("#D0E7EF")).opacity(time < 2.1 ? 1 : 0), radius: 26.8, y: 24)
        .scaleEffect(x: reduceMotion ? 2 : value("1904:6939", "--motion-scale-x", time, 2),
                     y: reduceMotion ? 2 : value("1904:6939", "--motion-scale-y", time, 2))
        .offset(x: (45.3 + (reduceMotion ? 80.13 : value("1904:6939", "--motion-translate-x", time, 80.13))) * ratio,
                y: (285.49 + (reduceMotion ? 29.27 : value("1904:6939", "--motion-translate-y", time, 29.27))) * ratio)
        .opacity(time < 2.45 ? 1 : max(0, 1 - (time - 2.45) / 0.3))
    }
}

private struct CottonLoadingCharacter: View {
    let time: Double
    private let motion = RoomLoadingTimeline.cotton
    private func value(_ id: String, _ property: String, _ fallback: Double = 0) -> Double {
        motion.value(id, property, at: time, fallback: fallback)
    }
    private func animated(_ id: String, asset: String, width: Double, height: Double, x: Double, y: Double) -> some View {
        Image(asset).resizable().frame(width: width, height: height)
            .scaleEffect(x: value(id, "--motion-scale-x", 1), y: value(id, "--motion-scale-y", 1))
            .offset(x: x + value(id, "--motion-translate-x"), y: y + value(id, "--motion-translate-y"))
            .opacity(value(id, "opacity", 1))
    }
    var body: some View {
        ZStack(alignment: .topLeading) {
            animated("1918:7553", asset: "loading_shadow", width: 95.04, height: 12.96, x: 31.68, y: 154.08)
            ZStack(alignment: .topLeading) {
                animated("1935:6512", asset: "loading_body_mongle", width: 131.884, height: 134.04, x: 13.258, y: 12.18)
                animated("1935:6514", asset: "loading_body_round", width: 133.895, height: 134.04, x: 12.276, y: 12.18)
                animated("1935:6516", asset: "loading_body_soft", width: 123.964, height: 134.04, x: 17.218, y: 12.18)
                animated("1935:6518", asset: "loading_body_fluffy", width: 133.119, height: 134.04, x: 12.641, y: 12.18)
                ForEach(0..<2) { index in
                    let id = index == 0 ? "1935:6519" : "1935:6520"
                    RoundedRectangle(cornerRadius: 6.854).fill(.white)
                        .frame(width: value(id, "width", 13.708), height: value(id, "height", 22.846))
                        .scaleEffect(x: value(id, "--motion-scale-x", 1), y: value(id, "--motion-scale-y", 1))
                        .offset(x: (index == 0 ? 58.64 : 86.05) + value(id, "--motion-translate-x"),
                                y: 66.25 + value(id, "--motion-translate-y"))
                }
                animated("1935:6521", asset: "loading_lid_left", width: 24.369, height: 19.8, x: 53.31, y: 88.34)
                animated("1935:6522", asset: "loading_lid_right", width: 24.369, height: 19.8, x: 80.72, y: 88.34)
            }.frame(width: 158.4, height: 158.4, alignment: .topLeading)
                .scaleEffect(x: value("1935:6510", "--motion-scale-x", 1), y: value("1935:6510", "--motion-scale-y", 1))
                .offset(x: value("1935:6510", "--motion-translate-x"), y: value("1935:6510", "--motion-translate-y"))
        }.frame(width: 158.4, height: 169.92, alignment: .topLeading).accessibilityHidden(true)
    }
}
