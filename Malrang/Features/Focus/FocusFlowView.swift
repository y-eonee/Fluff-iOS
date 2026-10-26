import SwiftData
import SwiftUI

struct FocusFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Doll.createdAt) private var dolls: [Doll]
    @Query private var items: [RoomItem]
    @State private var session = FocusSession()
    @State private var selection: UUID?
    @State private var showMain = false
    @State private var choosingDoll = true
    @State private var creating = false
    @State private var confirmingExit = false
    @State private var showingReward = false
    @State private var decoratingReward = false
    @State private var saveFailed = false
    @State private var happyUntil = Date.distantPast
    @State private var touchCount = 0
    private let roomSnapshot: UIImage?
    init(session: FocusSession = FocusSession(), showMain: Bool = false, showReward: Bool = false, roomSnapshot: UIImage? = nil) {
        self.roomSnapshot = roomSnapshot
        _session = State(initialValue: session); _showMain = State(initialValue: showMain); _showingReward = State(initialValue: showReward)
    }
    private var selected: Doll? { dolls.first { $0.id == session.record.dollID } }

    var body: some View {
        NavigationStack {
            Group {
                if session.active { running }
                else if showMain, let selected { main(selected) }
                else {
                    GeometryReader { geometry in
                        Group {
                            if let roomSnapshot { Image(uiImage: roomSnapshot).resizable() }
                            else { Image("focus_room").resizable() }
                        }.scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    }.ignoresSafeArea().accessibilityHidden(true)
                }
            }
            .foregroundStyle(FocusStyle.ink)
            .background(FocusStyle.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .overlay {
                if choosingDoll && !showMain && !session.active {
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            Color.black.opacity(0.18).ignoresSafeArea()
                                .onTapGesture { dismiss() }
                            VStack(spacing: 0) {
                                Capsule().fill(FocusStyle.line).frame(width: 36, height: 4)
                                    .padding(.top, 24)
                                    .accessibilityHidden(true)
                                selectionView
                            }
                            .frame(height: geometry.size.height * 0.60)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                            .background(FocusStyle.paper, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                            .accessibilityAction(.escape) { dismiss() }
                        }.ignoresSafeArea(edges: .bottom)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingReward) { reward }
            .alert("소품을 저장하지 못했어요", isPresented: $saveFailed) { Button("다시 확인", role: .cancel) {} }
            .accessibilityHidden(confirmingExit)
            .overlay { if confirmingExit { exitDialog } }
            .task {
                if session.active, selected == nil { session.stop() }
                while !Task.isCancelled {
                    session.tick()
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            .onChange(of: scenePhase) { if scenePhase == .active { session.tick() } }
            .sensoryFeedback(.impact(weight: .light), trigger: touchCount)
            .task(id: happyUntil) {
                guard happyUntil > .now else { return }
                let delay = happyUntil.timeIntervalSinceNow
                try? await Task.sleep(for: .seconds(max(0, delay)))
                guard !Task.isCancelled else { return }
                happyUntil = .distantPast
            }
        }
    }

    private func header(_ title: String, action: @escaping () -> Void) -> some View {
        Text(title).notCliche(28, relativeTo: .title).tracking(-1.12)
            .frame(maxWidth: .infinity).frame(height: 44)
            .overlay(alignment: .leading) {
                Button(action: action) { Image("a_back").resizable().frame(width: 24, height: 24).frame(width: 44, height: 44) }.accessibilityLabel("뒤로")
            }.padding(.horizontal, 20)
    }

    private var selectionView: some View {
        VStack(spacing: 18) {
            Text("솜뭉치랑 집중하기").pretendard(.bold, 20).padding(.top, 24)
            ScrollView {
                if dolls.isEmpty {
                    ContentUnavailableView("함께할 인형이 없어요", systemImage: "teddybear", description: Text("사진으로 첫 솜뭉치를 만들어 주세요."))
                    Button("인형 만들기") { creating = true }.buttonStyle(FocusPrimaryButton())
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(dolls) { doll in
                            let chosen = selection == doll.id
                            Button { selection = doll.id } label: {
                                VStack(spacing: 4) {
                                    DollThumbnail(data: doll.imageData, maxPixel: 280).frame(height: 93)
                                    Text(doll.name).pretendard(.medium, 16)
                                }.frame(maxWidth: .infinity).frame(height: 126)
                                    .background(chosen ? Color.white : FocusStyle.paper, in: RoundedRectangle(cornerRadius: 20))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(chosen ? FocusStyle.shade : FocusStyle.line, style: StrokeStyle(lineWidth: 1.5, dash: chosen ? [] : [3, 3])))
                            }.buttonStyle(.plain).accessibilityAddTraits(chosen ? .isSelected : [])
                        }
                    }.padding(.horizontal, 30)
                }
            }
            Button("함께 시작하기") {
                guard let selection else { return }
                session.select(selection); showMain = true; choosingDoll = false
            }.buttonStyle(FocusPrimaryButton()).disabled(selection == nil || !dolls.contains { $0.id == selection })
        }.padding(.horizontal, 24).padding(.bottom, 14)
            .background(FocusStyle.paper).foregroundStyle(FocusStyle.ink)
            .fullScreenCover(isPresented: $creating) { CreateFlowView { doll in selection = doll.id } }
    }

    private func main(_ doll: Doll) -> some View {
        VStack(spacing: 0) {
            header("focus together") { showMain = false; choosingDoll = true }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(spacing: 0) {
                        Text("\(doll.name)와 총 함께한 시간").pretendard(.regular, 12).foregroundStyle(FocusStyle.muted).padding(.top, 22)
                        Text(FocusSession.summary(session.record.daily.values.reduce(0, +))).pretendard(.bold, 28)
                        Image("ui_focus_bubble").resizable().scaledToFit().frame(width: 188, height: 48)
                            .overlay {
                                Text("우리 열심히 해보자!").pretendard(.medium, 13)
                                    .multilineTextAlignment(.center).offset(y: -4)
                            }.padding(.top, 6)
                        Group {
                            if let configuration = doll.presetConfiguration {
                                PresetDollView(configuration: configuration, cameraDistance: 0.88, cameraTarget: 0.19)
                                    .renderedOnlyWhileVisible(background: .clear)
                            } else { dollArtwork(doll) }
                        }.frame(height: 200)
                    }.frame(maxWidth: .infinity).frame(height: 339, alignment: .top)
                        .background(alignment: .bottom) { Image("ui_focus_starburst").resizable().scaledToFit().frame(height: 261) }
                        .background(CreationStyle.yellow, in: RoundedRectangle(cornerRadius: 16))
                        .padding(8).background(CreationStyle.blue, in: RoundedRectangle(cornerRadius: 16))
                    Text("\(doll.name)가 만들 소품").pretendard(.medium, 13)
                    HStack(spacing: 10) {
                        ForEach([25, 45, 60], id: \.self) { minutes in
                            let chosen = session.record.focusMinutes == minutes
                            Button { session.configure(focus: minutes, rest: session.record.restMinutes) } label: {
                                VStack(spacing: 2) {
                                    CottonArtwork(pose: .flower).frame(width: 71, height: 60)
                                    Text("꽃 머리핀").pretendard(.medium, 11)
                                    Text("제작 시간 \(minutes)분").pretendard(.regular, 11).foregroundStyle(FocusStyle.muted)
                                }.frame(maxWidth: .infinity).frame(height: 106)
                                    .background(chosen ? Color.white : FocusStyle.paper, in: RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(chosen ? FocusStyle.shade : FocusStyle.line, style: StrokeStyle(lineWidth: 1.5, dash: chosen ? [] : [3, 3])))
                            }.buttonStyle(.plain).accessibilityAddTraits(chosen ? .isSelected : [])
                        }
                    }
                    Text("집중 시간 설정").pretendard(.medium, 13)
                    HStack {
                        Text("집중 \(session.record.focusMinutes)분").pretendard(.medium, 13)
                        Spacer()
                        Stepper("휴식 \(session.record.restMinutes)분", value: Binding(get: { session.record.restMinutes }, set: { session.configure(focus: session.record.focusMinutes, rest: $0) }), in: 1...30)
                            .pretendard(.medium, 13).fixedSize()
                    }
                    if !session.record.rewardIDs.isEmpty {
                        Button("완성한 소품 받기") { showingReward = true }.font(.subheadline.bold())
                    }
                }.padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 12)
            }.scrollIndicators(.hidden)
            Button("집중 시작하기") { session.start() }.buttonStyle(FocusPrimaryButton())
                .padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 15)
        }
    }

    private var running: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let happy = happyUntil > Date.now
            ZStack {
                if let selected {
                    TimelineView(.animation(minimumInterval: 0.8, paused: session.paused || reduceMotion)) { time in
                        let pose: CottonArtwork.Pose = session.resting ? (happy ? .happy : .idle) : session.paused ? .working : (Int(time.date.timeIntervalSince1970) % 2 == 0 ? .working : .workingAlternate)
                        Group {
                            if !showingReward && !decoratingReward, let configuration = selected.presetConfiguration {
                                PresetDollView(configuration: configuration, cameraDistance: 0.84, cameraTarget: 0.18, focusScene: true, working: !session.resting, happy: happy, animating: !session.paused && !reduceMotion && scenePhase == .active)
                                    .renderedOnlyWhileVisible(background: .clear)
                            } else if selected.shapeRaw == "cat" { CottonArtwork(pose: pose) }
                            else { dollArtwork(selected) }
                        }
                        .frame(width: landscape ? geometry.size.width * 0.36 : geometry.size.width * 0.79,
                               height: landscape ? geometry.size.height * 0.85 : geometry.size.height * (session.resting ? 0.34 : 0.42))
                        .overlay(alignment: .top) {
                            if happy && session.resting {
                                HStack(alignment: .top, spacing: 36) {
                                    Image(systemName: "heart.fill").offset(y: 18)
                                    Image(systemName: "heart.fill").font(.title)
                                    Image(systemName: "heart.fill").offset(y: 28)
                                }.foregroundStyle(Color.a.pink).accessibilityHidden(true).allowsHitTesting(false)
                            }
                        }
                        .overlay {
                            Color.clear.contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0).onChanged { _ in
                                    guard session.resting, !session.paused else { return }
                                    if happyUntil < .now { touchCount += 1 }
                                    happyUntil = .now.addingTimeInterval(2)
                                })
                        }
                        .position(x: geometry.size.width * (landscape ? 0.78 : 0.5), y: geometry.size.height * (landscape ? 0.55 : (session.resting ? 0.43 : 0.40)))
                        .accessibilityLabel("\(selected.name), 쉬는 동안 쓰다듬어 주세요")
                    }
                }
                LinearGradient(stops: [.init(color: FocusStyle.shade.opacity(landscape ? 0 : 0.02), location: 0), .init(color: FocusStyle.shade.opacity(landscape ? 0 : 0.72), location: 0.26), .init(color: FocusStyle.shade.opacity(landscape ? 0 : 0.96), location: 1)], startPoint: .top, endPoint: .bottom)
                    .frame(height: landscape ? nil : geometry.size.height * 0.50)
                    .frame(maxHeight: .infinity, alignment: .bottom).allowsHitTesting(false).ignoresSafeArea(edges: .bottom)
                VStack(alignment: .leading) {
                    Button { confirmingExit = true } label: {
                        Image(systemName: "chevron.left").frame(width: 44, height: 44).background(FocusStyle.paper, in: Circle())
                    }.accessibilityLabel("집중 화면 나가기")
                    Spacer()
                }.padding(FocusStyle.inset).frame(maxWidth: .infinity, alignment: .leading)
                if session.resting && !landscape {
                    Text("쉬는 시간이에요!").pretendard(.medium, 11).foregroundStyle(.white)
                        .padding(.horizontal, 16).frame(height: 30)
                        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white, lineWidth: 1.2))
                        .position(x: geometry.size.width / 2, y: max(110, geometry.safeAreaInsets.top + 52))
                }
                if session.resting {
                    Text(happy ? "헤헤, 네 손은 정말 따뜻해 ♡" : "우리 조금만 쉬자! 놀아줘!")
                        .font(.footnote.weight(.medium)).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(Spacing.m).frame(width: min(280, geometry.size.width * (landscape ? 0.40 : 0.80)))
                        .background(FocusStyle.paper, in: Capsule())
                        .position(x: geometry.size.width * (landscape ? 0.77 : 0.5), y: geometry.size.height * (landscape ? 0.25 : 0.21))
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(session.resting ? "쉬는 시간" : (session.paused ? "집중 일시정지" : "현재 집중 시간")).font(.body.weight(.medium))
                    Text(FocusSession.clock(session.resting ? session.remaining : session.record.seconds, hours: !session.resting))
                        .font(.system(size: session.resting ? 76 : FocusStyle.timerSize, weight: .semibold)).monospacedDigit().tracking(-2).minimumScaleFactor(0.65).lineLimit(1)
                    HStack(alignment: .bottom, spacing: Spacing.l) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("총 함께한 시간").font(.caption)
                            Text(FocusSession.clock(session.today())).font(.title3).monospacedDigit()
                        }
                        if !session.resting {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("휴식까지").font(.caption)
                                Text(FocusSession.clock(session.remaining, hours: false)).font(.title3).monospacedDigit()
                            }
                        }
                        if !landscape { Spacer(minLength: 0); pauseButton }
                    }
                }.foregroundStyle(.white)
                    .padding(landscape ? 20 : 0)
                    .frame(width: landscape ? geometry.size.width * 0.44 : geometry.size.width - 48, alignment: .leading)
                    .background {
                        if landscape { RoundedRectangle(cornerRadius: 36).fill(.ultraThinMaterial.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 36).stroke(.white, lineWidth: 1.2)) }
                    }
                    .position(x: geometry.size.width * (landscape ? 0.23 : 0.5), y: geometry.size.height * (landscape ? 0.71 : 0.74))
                if landscape { pauseButton.position(x: geometry.size.width - 52, y: geometry.size.height - 52) }
                VStack {
                    Spacer()
                    if session.resting {
                        HStack {
                            if !session.record.rewardIDs.isEmpty { Button("완성한 소품 받기") { showingReward = true } }
                            Spacer()
                            Button("다시 집중하기") { session.nextFocus() }
                        }.foregroundStyle(.white).font(.footnote).padding(Spacing.m)
                    }
                }.padding(FocusStyle.inset)
                if !session.resting && !landscape {
                        HStack(spacing: Spacing.s) {
                            CottonArtwork(pose: .flower).frame(width: 40)
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("꽃 머리핀을 만들고 있어요").font(.caption)
                                Text("한 땀 더 완성 · \(Int(session.progress * 100))%").font(.caption2)
                            }
                            Spacer()
                            Button { confirmingExit = true } label: { Image(systemName: "stop").frame(width: 44, height: 44) }.accessibilityLabel("집중 종료")
                        }.foregroundStyle(.white).padding(Spacing.s)
                            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.25)))
                        .frame(width: geometry.size.width - 48, height: 62)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.94)
                }
                if landscape {
                    VStack(spacing: 8) {
                        Text(session.resting ? "쉬는 시간이에요!" : "꽃 머리핀 · \(Int(session.progress * 100))% 완성")
                            .pretendard(.medium, 11).foregroundStyle(.white).padding(8)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white))
                        if !session.resting { ProgressView(value: session.progress).tint(.white).frame(width: geometry.size.width * 0.42) }
                    }.position(x: geometry.size.width / 2, y: 65)
                }
            }
        }.background {
            GeometryReader { geometry in
                Image("focus_room").resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
            }.ignoresSafeArea()
        }
    }

    private var pauseButton: some View {
        Button { session.togglePause() } label: {
            Image(systemName: session.paused ? "play" : "pause").frame(width: 54, height: 54)
                .foregroundStyle(FocusStyle.ink).background(FocusStyle.paper, in: Circle())
        }.accessibilityLabel(session.paused ? "다시 시작" : "일시정지")
    }
    @ViewBuilder private func dollArtwork(_ doll: Doll) -> some View {
        if let configuration = doll.presetConfiguration, configuration.parts.isEmpty, configuration.face == nil { CottonArtwork(shape: configuration.shape) }
        else { Image(uiImage: doll.image).resizable().scaledToFit() }
    }
    private var exitDialog: some View {
        ZStack {
            FocusStyle.shade.opacity(0.28).ignoresSafeArea()
            VStack(spacing: Spacing.l) {
                Image(systemName: "clock").font(.title3).frame(width: 40, height: 40).background(FocusStyle.canvas, in: Circle())
                Text("집중 화면에서 나갈까요?").font(.title3.bold())
                Text("지금까지의 집중 시간은 기록에 남아요.\n나가면 집중 메인으로 돌아가요.").font(.footnote).foregroundStyle(FocusStyle.muted).multilineTextAlignment(.center)
                HStack(spacing: Spacing.s) {
                    Button("나가기") { session.stop(); showMain = true; confirmingExit = false }.frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(FocusStyle.line))
                    Button("머무르기") { confirmingExit = false }.buttonStyle(FocusPrimaryButton())
                }
            }.padding(FocusStyle.inset).background(FocusStyle.paper, in: RoundedRectangle(cornerRadius: 28)).padding(FocusStyle.inset)
        }
    }
    private var reward: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("꽃 머리핀이 완성됐어요!").pretendard(.bold, 24).padding(.top, 50)
                        ZStack {
                            RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [FocusStyle.giftTop, FocusStyle.giftBottom], startPoint: .top, endPoint: .bottom))
                            Capsule().fill(FocusStyle.line.opacity(0.6)).frame(width: 246, height: 28).offset(y: 82)
                            CottonArtwork(pose: .flower).frame(width: 180, height: 154).offset(y: -14)
                            Text("✦").font(.system(size: 32)).foregroundStyle(Color.a.pinkLight).offset(x: -120, y: -85)
                            Text("✧").font(.system(size: 36)).foregroundStyle(Color.a.pinkLight).offset(x: 124, y: 42)
                        }.frame(height: 300)
                        HStack {
                            VStack(spacing: 4) { Text("이번 집중").pretendard(.regular, 11); Text("\(session.record.completedMinutes)분").pretendard(.bold, 22) }
                                .frame(maxWidth: .infinity)
                            VStack(spacing: 4) { Text("총 누적").pretendard(.regular, 11); Text(FocusSession.summary(session.record.daily.values.reduce(0, +))).pretendard(.bold, 22) }
                                .frame(maxWidth: .infinity)
                        }.frame(height: 94).background(FocusStyle.paper, in: RoundedRectangle(cornerRadius: 24))
                    }.padding(.horizontal, 24)
                }
                Button("꾸며주러 가기", action: claimReward).buttonStyle(FocusPrimaryButton())
                    .disabled(session.record.rewardIDs.isEmpty).padding(.horizontal, 24).padding(.bottom, 15)
            }.background(FocusStyle.canvas).foregroundStyle(FocusStyle.ink)
                .navigationDestination(isPresented: $decoratingReward) { DecorateView() }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showingReward = false } label: { Label("솜뭉치의 선물", systemImage: "chevron.left").labelStyle(.titleAndIcon) }
                    }.sharedBackgroundVisibility(.hidden)
                }
        }
    }
    private func claimReward() {
        guard let id = session.record.rewardIDs.first else { return }
        // Stable reward IDs make claiming idempotent even if the process stops between saves.
        if !items.contains(where: { $0.id == id }) {
            let item = RoomItem(kind: .flowerCushion, x: 0.30, z: 0.8); item.id = id
            context.insert(item)
            do { try context.save() } catch { context.delete(item); saveFailed = true; return }
        }
        session.claim(id); decoratingReward = true
    }
}

#Preview { FocusFlowView().modelContainer(.preview) }
