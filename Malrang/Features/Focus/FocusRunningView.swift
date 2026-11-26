import SwiftUI

extension FocusFlowView {
    var running: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > geometry.size.height
            ZStack(alignment: .topLeading) {
                FocusReferenceBackground(size: geometry.size)
                if let selected {
                    Group {
                        if let configuration = selected.presetConfiguration {
                            PresetDollView(configuration: configuration, cameraDistance: 0.82, cameraTarget: 0.18,
                                           cameraYaw: -0.12, cameraPitch: 0.08,
                                           fitsModel: true, fitMargin: 1.10, focusScene: true, showsStudyDesk: false, working: !session.resting,
                                           happy: happyUntil > .now, animating: !reduceMotion && !session.paused)
                                .renderedOnlyWhileVisible(background: .clear)
                        } else {
                            Image(uiImage: selected.image).resizable().scaledToFit().padding(28)
                        }
                    }
                    .frame(width: geometry.size.width * (wide ? 0.42 : 0.92), height: geometry.size.height * (wide ? 0.72 : 0.48))
                    .contentShape(Rectangle()).onTapGesture { pet() }
                    .position(x: geometry.size.width * (wide ? 0.72 : 0.52), y: geometry.size.height * (wide ? 0.46 : 0.48))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .mask(alignment: .top) {
                        Rectangle().frame(height: geometry.size.height * (wide ? 0.86 : 0.635))
                    }
                    // Recreate the render surface after rotation; retaining the
                    // portrait Metal surface can leave the landscape doll blank.
                    .id("\(selected.id)-\(wide)")
                    .accessibilityLabel("\(selected.name)와 함께 집중 중")
                }
                LinearGradient(stops: RepresentativeGradients.focusTimer.stops, startPoint: wide ? .trailing : .top, endPoint: wide ? .leading : .bottom)
                    .frame(width: geometry.size.width * (wide ? 0.685 : 1), height: geometry.size.height * (wide ? 1 : 0.502))
                    .position(x: geometry.size.width * (wide ? 0.3425 : 0.5), y: geometry.size.height * (wide ? 0.5 : 0.749))
                    .allowsHitTesting(false)
                Button { confirmingExit = true } label: {
                    Image("rep4_back_light").resizable().scaledToFit().frame(width: 38, height: 38).frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel("집중 화면 나가기")
                    .padding(.leading, wide ? 24 : 18).padding(.top, wide ? 24 : geometry.size.height * 0.065)
                if wide {
                    VStack(alignment: .leading, spacing: 33.57) {
                        studyProgress.frame(width: 326)
                        timerPanel.frame(width: 324)
                    }.padding(.leading, max(32, geometry.safeAreaInsets.leading))
                        .padding(.top, geometry.size.height * 95.43 / 390)
                } else {
                    VStack(spacing: 0) {
                        studyProgress.padding(.horizontal, 32)
                        Spacer(minLength: 24)
                        timerPanel.padding(.horizontal, 33)
                    }.padding(.leading, geometry.safeAreaInsets.leading).padding(.trailing, geometry.safeAreaInsets.trailing)
                        .padding(.top, geometry.size.height * 0.148)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom + 38, geometry.size.height * 0.083))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading).clipped().accessibilityHidden(confirmingExit)
        }.ignoresSafeArea()
    }

    private var studyProgress: some View {
        VStack(spacing: 10) {
            if session.resting {
                Text(happyUntil > .now ? "헤헤, 네 손은 정말 따뜻해 ♡" : "인형과 함께 잠깐 쉬어가세요.")
                    .pretendard(.semiBold, 15).frame(maxWidth: .infinity)
            } else {
                HStack {
                    Text("오늘 목표")
                    Spacer()
                    Text("1시간 · \(Int(session.goalProgress * 100))% 달성")
                }.pretendard(.semiBold, 15.789, tracking: -0.789)
                GeometryReader { proxy in
                    Capsule().fill(Color.rep4.c20)
                    Capsule().fill(FlowDesign.lightBlue).frame(width: proxy.size.width * min(1, max(0, session.goalProgress)))
                    Capsule().strokeBorder(Color.rep4.c01.opacity(0.6), lineWidth: 0.5)
                }.frame(height: 8)
            }
        }.foregroundStyle(Color.rep4.c01).padding(.horizontal, 17).frame(height: 66)
            .background { RepresentativeGradientFill(definition: RepresentativeGradients.focusGoal).clipShape(RoundedRectangle(cornerRadius: 15)) }

    }

    private var timerPanel: some View {
        GeometryReader { proxy in
            // Navigation can briefly propose zero width before layout settles.
            let width = proxy.size.width.isFinite ? max(0, proxy.size.width) : 0
            ZStack(alignment: .topLeading) {
                Text(session.resting ? "남은 휴식 시간" : "현재 집중 시간")
                    .pretendard(.bold, 17, tracking: -0.85)
                    .frame(height: 26).shadow(color: .black.opacity(0.26), radius: 5, x: 1, y: 3)
                    .offset(x: 5)
                Text(FocusSession.clock(session.resting ? session.remaining : session.record.seconds, hours: !session.resting))
                    .pretendard(.regular, 62, tracking: -3.1).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(width: max(0, width - 82), height: 80, alignment: .leading)
                    .shadow(color: .black.opacity(0.1), radius: 6.8, x: 1, y: 3)
                    .offset(x: -0.92, y: 20.4)
                Button { session.togglePause() } label: {
                    if session.paused {
                        D1PlaybackGlyph(paused: true, color: Color.rep4.c01).frame(width: 73.563, height: 73.563)
                            .background(Color.rep4.c19, in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 0.5))
                    } else {
                        Image("rep4_focus_pause").resizable().frame(width: 73.563, height: 73.563)
                    }
                }.buttonStyle(.plain).contentShape(Circle()).accessibilityLabel(session.paused ? "집중 이어하기" : "일시정지")
                    .offset(x: width - 69.25, y: 17.08)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.rep4.c20).frame(height: 7.936)
                        .overlay(Capsule().strokeBorder(Color(uiColor: Palette.uiColor("#7A7A7A")), lineWidth: 0.635))
                    Capsule().fill(FlowDesign.lightBlue).frame(width: width * setProgress, height: 6.735)
                }.frame(height: 15).offset(y: 114.70)
                HStack {
                    Text("\(session.resting ? "휴식" : "집중") · \(FocusSession.clock(session.record.seconds, hours: false))")
                    Spacer()
                    Text("\(session.resting ? "시작 남음" : "휴식까지") · \(FocusSession.clock(session.remaining, hours: false))")
                }.pretendard(.regular, 14).frame(minHeight: 21)
                    .padding(.leading, 2).offset(y: 137.06)
            }
        }.frame(height: 152.285).foregroundStyle(Color.rep4.c01)
            .contextMenu { if session.resting { Button("휴식 시간 종료") { session.nextFocus() } } }
            .accessibilityAction(named: "휴식 시간 종료") { if session.resting { session.nextFocus() } }
    }
    private var setProgress: Double {
        let seconds = Double((session.resting ? session.record.restMinutes : session.record.focusMinutes) * 60)
        return min(1, max(0, 1 - session.remaining / max(1, seconds)))
    }
    private func pet() {
        guard session.resting, !session.paused else { return }
        if happyUntil < .now {
            touchCount += 1
            if let selected { DollActivityRecorder.record(.touch, ids: [selected.id], in: modelContext) }
        }
        happyUntil = .now.addingTimeInterval(2)
    }
}

/// Preserve the original room and desk. Only the fixed character's region is
/// replaced by the clean plate, so rendering the user's doll never duplicates it.
private struct FocusReferenceBackground: View {
    let size: CGSize
    var body: some View {
        if size.width > size.height {
            landscape
        } else {
            portrait
        }
    }

    private var landscape: some View {
        // The landscape frame uses its own wider room image, not a stretched
        // portrait crop. Keep the selected doll live in the character's slot.
        let width = size.width * 976.704 / 844
        let height = size.height * 928.038 / 390
        return ZStack(alignment: .topLeading) {
            Image("flow_focus_landscape").resizable()
            Image("rep4_focus_room_clean").resizable()
                .frame(width: width * 768 / 1886, height: height)
                .offset(x: width * 0.478)
                .frame(width: width, height: height, alignment: .topLeading)
                .mask {
                    Rectangle().frame(width: width * 0.30, height: height * 0.32)
                        .position(x: width * 0.69, y: height * 0.57)
                }
        }.frame(width: width, height: height)
            .offset(x: -size.width * 66.307 / 844, y: -size.height * 348.201 / 390)
            .blur(radius: 2.132).accessibilityHidden(true)
    }

    private var portrait: some View {
        let width = size.width * 1.156, height = size.height * 1.223
        return ZStack {
            Image("rep4_focus_background").resizable()
            Image("rep4_focus_room_clean").resizable()
                .mask {
                    Rectangle().frame(width: width * 0.66, height: height * 0.275)
                        .position(x: width * 0.525, y: height * 0.565)
                }
        }.frame(width: width, height: height)
            .offset(x: -size.width * 0.084, y: -size.height * 0.223)
            .blur(radius: 2.13).accessibilityHidden(true)
    }
}
