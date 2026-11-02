import SwiftUI

extension FocusFlowView {
    var running: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let happy = happyUntil > Date.now
            ZStack {
                if let selected {
                    companion(selected, happy: happy)
                        .frame(width: landscape ? geometry.size.width * 0.37 : geometry.size.width * 0.79,
                               height: landscape ? geometry.size.height * 0.85 : (session.resting ? 264 : 334))
                        .position(x: geometry.size.width * (landscape ? 0.78 : 0.5), y: geometry.size.height * (landscape ? 0.55 : (session.resting ? 0.43 : 0.35)))
                }
                VStack {
                    HStack {
                        focusIcon("backLight", label: "집중 화면 나가기") { confirmingExit = true }
                        Spacer()
                    }
                    Spacer()
                }.padding(.horizontal, 22).padding(.top, 10)
                if landscape {
                    timerPanel(landscape: true)
                        .frame(width: min(390, geometry.size.width * 0.46), height: 252)
                        .position(x: 22 + min(390, geometry.size.width * 0.46) / 2, y: geometry.size.height - 26 - 126)
                    VStack(spacing: 8) {
                        Text(session.resting ? "쉬는 시간이에요!" : "같이 \(session.activity.ongoing) 중 · 오늘 목표 \(goalPercent)%")
                            .pretendard(.medium, 13).padding(.horizontal, 12).frame(height: 36).focusPanel()
                        if !session.resting { ProgressView(value: session.goalProgress).tint(FocusStyle.sage).frame(width: 182) }
                    }.position(x: geometry.size.width / 2, y: 34)
                } else {
                    VStack(spacing: 12) {
                        Spacer(minLength: 0)
                        if !session.resting { studyProgress }
                        timerPanel(landscape: false).frame(height: 254)
                    }.padding(.horizontal, 16).padding(.bottom, 16)
                }
                if session.resting {
                    D1Bubble(text: happy ? "헤헤, 네 손은 정말 따뜻해 ♡" : (landscape ? "놀아줘! 쓰다듬어 줄래?" : "우리 조금만 쉬자! 놀아줘!"))
                        .frame(width: min(280, geometry.size.width * 0.80))
                        .position(x: geometry.size.width * (landscape ? 0.77 : 0.5), y: geometry.size.height * (landscape ? 0.13 : 0.21))
                    if !landscape {
                        Text("쉬는 시간이에요!").pretendard(.medium, 13)
                            .padding(.horizontal, 16).frame(height: 36).focusPanel()
                            .position(x: geometry.size.width / 2, y: 44)
                    }
                }
            }.accessibilityHidden(confirmingExit)
        }.background {
            GeometryReader { geometry in
                Image("focus_room").resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
            }.ignoresSafeArea()
        }
    }

    private var goalPercent: Int { Int(session.goalProgress * 100) }

    private func companion(_ doll: Doll, happy: Bool) -> some View {
        Group {
            if let configuration = doll.presetConfiguration {
                PresetDollView(configuration: configuration, cameraDistance: 0.84, cameraTarget: 0.18,
                               focusScene: true, working: !session.resting, happy: happy,
                               animating: !session.paused && !reduceMotion && scenePhase == .active)
                    .renderedOnlyWhileVisible(background: .clear)
            } else {
                RoomSceneView(items: [], dolls: [doll.state], mode: .view, isTransparent: true)
                    .renderedOnlyWhileVisible(background: .clear)
            }
        }
        .overlay(alignment: .top) {
            if happy && session.resting {
                HStack(spacing: 30) { ForEach(0..<3) { _ in Image(systemName: "heart.fill") } }
                    .foregroundStyle(Color.mib.action.primary).accessibilityHidden(true).allowsHitTesting(false)
            }
        }
        .overlay {
            Color.clear.contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { _ in pet() })
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(session.resting ? "\(doll.name), 쉬는 동안 쓰다듬어 주세요" : "\(doll.name), 함께 \(session.activity.ongoing) 중")
        .accessibilityAction(named: "쓰다듬기") { pet() }
    }

    private func pet() {
        guard session.resting, !session.paused else { return }
        if happyUntil < .now { touchCount += 1 }
        happyUntil = .now.addingTimeInterval(2)
    }

    private var studyProgress: some View {
        HStack(spacing: 8) {
            D1Icon(name: session.activity.icon).frame(width: 44, height: 44)
                .background(Color.mib.bg.mintSoft, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selected?.name ?? "솜뭉치")도 옆에서 \(session.activity.ongoing) 중이에요").pretendard(.medium, 13)
                Text("오늘 목표 1시간 · \(goalPercent)% 달성").pretendard(.medium, 13).foregroundStyle(FocusStyle.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            D1IconButton(icon: "stop", label: "집중 종료") { confirmingExit = true }
        }.padding(8).d1ImageSurface(radius: 14).padding(.horizontal, 6)
    }

    private func timerPanel(landscape: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.resting ? "쉬는 시간" : session.paused ? "집중 일시정지" : "현재 집중 시간")
                .pretendard(.bold, 17).padding(.trailing, 48)
            Text(FocusSession.clock(session.resting ? session.remaining : session.record.seconds, hours: !session.resting))
                .pretendard(.bold, 64).monospacedDigit().tracking(-2).lineLimit(1).minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .leading).frame(height: 80)
            HStack(alignment: .top, spacing: 24) {
                stat("총 함께한 시간", value: FocusSession.clock(selected.map { session.total(with: $0.id) } ?? 0))
                if !session.resting { stat("휴식까지", value: FocusSession.clock(session.remaining, hours: false)) }
            }
            Spacer(minLength: 0)
            if session.resting {
                Button("다시 집중하기") { session.nextFocus() }.buttonStyle(FocusCompactButton())
            }
        }.padding(22).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .focusPanel()
            .overlay(alignment: .topTrailing) {
                focusIcon(session.paused ? "play" : "pause", label: session.paused ? "다시 시작" : "일시정지") { session.togglePause() }
                    .padding(landscape ? 18 : 16)
            }
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).pretendard(.medium, 13).foregroundStyle(FocusStyle.muted)
            Text(value).pretendard(.bold, 21).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func focusIcon(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            D1Icon(name: icon).frame(width: 44, height: 44).contentShape(Rectangle())
                .background(FocusStyle.sage, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.mib.text.onPrimary.opacity(0.7)))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}
