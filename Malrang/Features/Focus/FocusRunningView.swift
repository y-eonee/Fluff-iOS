import SwiftUI

extension FocusFlowView {
    var running: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let happy = happyUntil > Date.now
            ZStack(alignment: .topLeading) {
                if let selected {
                    companion(selected, happy: happy)
                        .frame(width: landscape ? geometry.size.width * 0.37 : geometry.size.width * 0.79,
                               height: landscape ? geometry.size.height * 0.85 : geometry.size.height * 0.43)
                        .position(x: geometry.size.width * (landscape ? 0.78 : 0.5),
                                  y: geometry.size.height * (landscape ? 0.53 : 0.43))
                }
                focusIcon("back", label: "집중 화면 나가기") { confirmingExit = true }
                    .padding(.leading, 22).padding(.top, 10)
                if landscape {
                    timerPanel(landscape: true)
                        .frame(width: min(390, geometry.size.width * 0.49))
                        .frame(maxHeight: .infinity, alignment: .bottom).padding(.leading, 24).padding(.bottom, 24)
                    if session.resting {
                        restMessage(happy: happy).position(x: geometry.size.width * 0.77, y: 30)
                    }
                } else {
                    VStack(spacing: 0) {
                        if session.resting { restMessage(happy: happy) }
                        else { studyProgress }
                        Spacer(minLength: 0)
                        timerPanel(landscape: false).padding(.horizontal, 16)
                    }.padding(.top, 71).padding(.bottom, 16)
                }
            }.accessibilityHidden(confirmingExit)
        }.background {
            roomBackground.ignoresSafeArea()
        }
    }

    private func restMessage(happy: Bool) -> some View {
        Text(happy ? "헤헤, 네 손은 정말 따뜻해 ♡" : "인형과 함께 잠깐 쉬어가세요.")
            .pretendard(.medium, 13).padding(.horizontal, 24).padding(.vertical, 8)
            .background(FocusStyle.paper, in: Capsule())
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
        if happyUntil < .now {
            touchCount += 1
            if let selected { DollActivityRecorder.record(.touch, ids: [selected.id], in: modelContext) }
        }
        happyUntil = .now.addingTimeInterval(2)
    }

    private var studyProgress: some View {
        HStack(spacing: 8) {
            D1Icon(name: session.activity.icon).frame(width: 44, height: 44)
                .background(Color.mib.bg.mintSoft, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.paused ? "집중을 잠시 멈췄어요" : "\(selected?.name ?? "인형")도 옆에서 \(session.activity.ongoing) 중이에요").pretendard(.medium, 13)
                Text("오늘 목표 1시간 · \(goalPercent)% 달성").pretendard(.medium, 13).foregroundStyle(FocusStyle.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            D1IconButton(icon: "stop", label: "집중 종료") { confirmingExit = true }
        }.padding(8).background(FocusStyle.paper, in: RoundedRectangle(cornerRadius: 14)).padding(.horizontal, 22)
    }

    private func timerPanel(landscape: Bool) -> some View {
        VStack(spacing: 16) {
            Text(session.resting ? "남은 휴식 시간" : session.paused ? "집중 일시정지" : "현재 집중 시간")
                .pretendard(.bold, 17).frame(maxWidth: .infinity)
            Text(FocusSession.clock(session.resting ? session.remaining : session.record.seconds, hours: !session.resting))
                .pretendard(.bold, 64).monospacedDigit().tracking(-2).lineLimit(1).minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity).frame(height: 80)
            Button {
                if session.resting { session.nextFocus() }
                else { session.togglePause() }
            } label: {
                HStack(spacing: 8) {
                    if !session.resting { D1Icon(name: session.paused ? "play" : "pause") }
                    Text(session.resting ? "휴식 시간 종료" : session.paused ? "집중 이어하기" : "일시정지")
                }
            }.buttonStyle(D1PrimaryStyle())
        }.padding(.horizontal, 16).padding(.vertical, landscape ? 16 : 24)
            .background(FocusStyle.paper, in: RoundedRectangle(cornerRadius: 22))
    }

    private func focusIcon(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            D1Icon(name: icon).frame(width: 44, height: 44).contentShape(Rectangle())
                .d1ImageSurface(radius: 22)
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}
