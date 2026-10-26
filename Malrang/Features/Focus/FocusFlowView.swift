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
    @State private var settings = false
    @State private var creating = false
    @State private var confirmingExit = false
    @State private var showingReward = false
    @State private var saveFailed = false
    @State private var happyUntil = Date.distantPast
    @State private var touchCount = 0
    init(session: FocusSession = FocusSession(), showMain: Bool = false, showReward: Bool = false) {
        _session = State(initialValue: session); _showMain = State(initialValue: showMain); _showingReward = State(initialValue: showReward)
    }
    private var selected: Doll? { dolls.first { $0.id == session.record.dollID } }

    var body: some View {
        NavigationStack {
            Group {
                if session.active { running }
                else if showMain, let selected { main(selected) }
                else { selectionView }
            }
            .foregroundStyle(FocusStyle.ink)
            .background(FocusStyle.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $settings) {
                FocusSettingsView(focus: session.record.focusMinutes, rest: session.record.restMinutes) { focus, rest in
                    session.configure(focus: focus, rest: rest); session.start(); settings = false
                }
                .presentationDetents([.height(470), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .fullScreenCover(isPresented: $creating) {
                CreateFlowView { doll in selection = doll.id }
            }
            .sheet(isPresented: $showingReward) { reward }
            .alert("소품을 저장하지 못했어요", isPresented: $saveFailed) { Button("다시 확인", role: .cancel) {} }
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
        }
    }

    private func header(_ title: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: Spacing.s) {
            Button(action: action) { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("뒤로")
            Text(title).font(.headline)
            Spacer()
        }.padding(.horizontal, Spacing.m)
    }

    private var selectionView: some View {
        VStack(spacing: 0) {
            header("함께 집중하기") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("함께 집중할 인형을\n골라주세요").font(.title2.bold()).lineSpacing(Spacing.xs)
                        Text("선택한 인형도 함께 공방 작업을 시작해요.").font(.footnote).foregroundStyle(FocusStyle.muted)
                    }.padding(.vertical, Spacing.l)
                    HStack { Text("보유한 인형").bold(); Text("\(dolls.count)").foregroundStyle(FocusStyle.muted) }.font(.subheadline)
                    if dolls.isEmpty {
                        ContentUnavailableView("함께할 인형이 없어요", systemImage: "teddybear", description: Text("사진 없이도 첫 솜뭉치를 만들 수 있어요."))
                        Button("인형 만들기") { creating = true }.buttonStyle(FocusPrimaryButton())
                    } else {
                        LazyVStack(spacing: Spacing.s) {
                            ForEach(dolls) { doll in
                                Button { selection = doll.id } label: {
                                    HStack(spacing: Spacing.s) {
                                        dollArtwork(doll).frame(width: 88, height: 93)
                                        Text(doll.name).font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: selection == doll.id ? "checkmark.circle.fill" : "circle")
                                            .font(.title2).foregroundStyle(selection == doll.id ? FocusStyle.ink : FocusStyle.line)
                                    }.padding(Spacing.s)
                                        .background(FocusStyle.paper, in: RoundedRectangle(cornerRadius: 22))
                                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(selection == doll.id ? FocusStyle.ink : FocusStyle.line, lineWidth: 1.5))
                                }.buttonStyle(.plain).accessibilityAddTraits(selection == doll.id ? .isSelected : [])
                            }
                        }
                    }
                }.padding(.horizontal, FocusStyle.inset)
            }
            VStack(spacing: Spacing.l) {
                Text("함께할 인형 1개를 선택해 주세요.").font(.footnote).foregroundStyle(FocusStyle.muted)
                Button(selection == nil ? "인형을 선택해 주세요" : "함께 집중하기") {
                    if let selection { session.select(selection); showMain = true }
                }.buttonStyle(FocusPrimaryButton()).disabled(selection == nil || !dolls.contains { $0.id == selection })
            }.padding(FocusStyle.inset)
        }
    }

    private func main(_ doll: Doll) -> some View {
        VStack(spacing: 0) {
            header("집중 with \(doll.name)") { showMain = false }
            ScrollView {
                VStack(spacing: Spacing.m) {
                    VStack(spacing: Spacing.s) {
                        Text("오늘 집중한 시간").font(.caption).foregroundStyle(FocusStyle.muted)
                        Text(FocusSession.summary(session.today())).font(.title.bold())
                        HStack {
                            ForEach(0..<7) { index in
                                let calendar = Calendar.current
                                let today = calendar.startOfDay(for: .now)
                                let weekday = (calendar.component(.weekday, from: today) + 5) % 7
                                let date = calendar.date(byAdding: .day, value: index - weekday, to: today)!
                                VStack(spacing: Spacing.xs) {
                                    Text(["월", "화", "수", "목", "금", "토", "일"][index]).font(.caption2)
                                    Circle().fill(session.minutes(on: date) > 0 ? FocusStyle.sage : FocusStyle.line).frame(width: 6, height: 6)
                                }.frame(maxWidth: .infinity).accessibilityLabel("\(index + 1)요일, \(session.minutes(on: date))분 집중")
                            }
                        }.padding(.top, Spacing.xs)
                    }.padding(FocusStyle.inset).frame(maxWidth: .infinity, minHeight: 167)
                        .background(FocusStyle.paper, in: RoundedRectangle(cornerRadius: FocusStyle.radius))
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            Image("focus_room").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
                            dollArtwork(doll).frame(width: 220, height: 232)
                            Text("우리 열심히 해보자!").font(.footnote.weight(.medium))
                                .padding(Spacing.m).frame(width: 228).background(FocusStyle.paper.opacity(0.96), in: Capsule())
                                .frame(maxHeight: .infinity, alignment: .top).padding(.top, Spacing.l)
                        }
                    }.frame(height: 312).clipShape(RoundedRectangle(cornerRadius: FocusStyle.radius))
                    HStack(spacing: Spacing.s) {
                        CottonArtwork(pose: .flower).frame(width: 42)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("오늘은 꽃 쿠션을 만들어요").font(.footnote.weight(.medium))
                            Text("집중 \(session.record.focusMinutes)분 · 완성하면 내 방에 놓기").font(.caption).foregroundStyle(FocusStyle.muted)
                        }
                        Spacer()
                    }.padding(Spacing.s).frame(minHeight: 66).background(FocusStyle.paper, in: RoundedRectangle(cornerRadius: 20))
                    if !session.record.rewardIDs.isEmpty {
                        Button("완성한 꽃 쿠션 받기") { showingReward = true }.font(.subheadline.bold())
                    }
                    Button("집중 시작하기") { settings = true }.buttonStyle(FocusPrimaryButton())
                    Text("이미 쌓은 시간에 이어서 기록돼요.").font(.caption).foregroundStyle(FocusStyle.muted)
                }.padding(FocusStyle.inset)
            }
        }
    }

    private var running: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let happy = happyUntil > Date.now
            ZStack {
                Image("focus_room").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped().ignoresSafeArea()
                if let selected {
                    TimelineView(.animation(minimumInterval: 0.8, paused: session.paused || reduceMotion)) { time in
                        let pose: CottonArtwork.Pose = session.resting ? (happy ? .happy : .idle) : (Int(time.date.timeIntervalSince1970) % 2 == 0 ? .working : .workingAlternate)
                        Group {
                            if selected.presetConfiguration != nil {
                                PresetDollView(configuration: selected.presetConfiguration!, working: !session.resting, happy: happy, animating: !session.paused && !reduceMotion)
                            } else if selected.shapeRaw == "cat" { CottonArtwork(pose: pose) }
                            else { dollArtwork(selected) }
                        }
                        .frame(width: landscape ? geometry.size.width * 0.36 : geometry.size.width * 0.79,
                               height: landscape ? geometry.size.height * 0.85 : geometry.size.height * 0.42)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { _ in
                            guard session.resting else { return }
                            if happyUntil < .now { touchCount += 1 }
                            happyUntil = .now.addingTimeInterval(2)
                        })
                        .position(x: geometry.size.width * (landscape ? 0.78 : 0.5), y: geometry.size.height * (landscape ? 0.55 : 0.40))
                        .accessibilityLabel("\(selected.name), 쉬는 동안 쓰다듬어 주세요")
                    }
                }
                LinearGradient(colors: [.clear, FocusStyle.shade.opacity(0.72), FocusStyle.shade.opacity(0.96)], startPoint: landscape ? .trailing : .top, endPoint: landscape ? .leading : .bottom)
                    .frame(height: landscape ? nil : geometry.size.height * 0.50)
                    .frame(maxHeight: .infinity, alignment: .bottom).allowsHitTesting(false).ignoresSafeArea(edges: .bottom)
                VStack(alignment: .leading) {
                    Button { confirmingExit = true } label: {
                        Image(systemName: "chevron.left").frame(width: 44, height: 44).background(FocusStyle.paper, in: Circle())
                    }.accessibilityLabel("집중 화면 나가기")
                    if !landscape {
                        HStack(spacing: 6) {
                            Circle().fill(FocusStyle.sage).frame(width: 6, height: 6)
                            Text(session.resting ? "쉬는시간!" : "\(selected?.name ?? "솜뭉치")도 열심히 작업중").font(.caption2)
                        }.padding(Spacing.xs).background(FocusStyle.paper, in: Capsule()).padding(.top, Spacing.s)
                    }
                    Spacer()
                }.padding(FocusStyle.inset).padding(.top, landscape ? 0 : max(44, geometry.safeAreaInsets.top)).frame(maxWidth: .infinity, alignment: .leading)
                if session.resting {
                    Text(happy ? "헤헤, 네 손은 정말 따뜻해 ♡" : "우리 조금만 쉬자! 놀아줘!")
                        .font(.footnote.weight(.medium)).padding(Spacing.m).background(FocusStyle.paper, in: Capsule())
                        .position(x: geometry.size.width * (landscape ? 0.77 : 0.5), y: geometry.size.height * (landscape ? 0.19 : 0.21))
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(session.resting ? "쉬는 시간" : (session.paused ? "집중 일시정지" : "현재 집중 시간")).font(.body.weight(.medium))
                    Text(FocusSession.clock(session.resting ? session.remaining : session.record.seconds, hours: !session.resting))
                        .font(.system(size: FocusStyle.timerSize, weight: .semibold)).monospacedDigit().tracking(-2).minimumScaleFactor(0.65).lineLimit(1)
                    HStack(alignment: .bottom, spacing: Spacing.l) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("오늘 총 시간").font(.caption)
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
                    .frame(width: landscape ? geometry.size.width * 0.48 : geometry.size.width - 48, alignment: .leading)
                    .position(x: geometry.size.width * (landscape ? 0.28 : 0.5), y: geometry.size.height * (landscape ? 0.5 : 0.73))
                if landscape { pauseButton.position(x: geometry.size.width - 52, y: geometry.size.height - 52) }
                VStack {
                    Spacer()
                    if session.resting {
                        HStack {
                            if !session.record.rewardIDs.isEmpty { Button("꽃 쿠션 받기") { showingReward = true } }
                            Spacer()
                            Button("다시 집중하기") { session.nextFocus() }
                        }.foregroundStyle(.white).font(.footnote).padding(Spacing.m)
                    } else if !landscape {
                        HStack(spacing: Spacing.s) {
                            CottonArtwork(pose: .flower).frame(width: 40)
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("꽃 쿠션을 만들고 있어요").font(.caption)
                                Text("한 땀 더 완성 · \(Int(session.progress * 100))%").font(.caption2)
                            }
                            Spacer()
                            Button { confirmingExit = true } label: { Image(systemName: "stop").frame(width: 44, height: 44) }.accessibilityLabel("집중 종료")
                        }.foregroundStyle(.white).padding(Spacing.s)
                            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.25)))
                    }
                }.padding(FocusStyle.inset)
            }.clipped()
        }.ignoresSafeArea()
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
                Image(systemName: "clock").font(.title2)
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
            ScrollView {
                VStack(spacing: Spacing.l) {
                    Text("우리의 시간이 만든 작은 선물").font(.caption).foregroundStyle(FocusStyle.muted)
                    Text("꽃 쿠션이 완성됐어요!").font(.title2.bold())
                    CottonArtwork(pose: .flower).frame(width: 180, height: 240).frame(maxWidth: .infinity)
                        .padding(Spacing.l).background(FocusStyle.line.opacity(0.4), in: RoundedRectangle(cornerRadius: 28))
                    HStack {
                        VStack { Text("이번 집중").font(.caption); Text("\(session.record.completedMinutes)분").font(.title2.bold()) }
                        Spacer()
                        VStack { Text("오늘 누적").font(.caption); Text(FocusSession.summary(session.today())).font(.title2.bold()) }
                    }.padding(FocusStyle.inset).background(FocusStyle.paper, in: RoundedRectangle(cornerRadius: FocusStyle.radius))
                    Text("네가 몰입하는 동안, 나도 열심히 만들었어.\n우리 방에 놓으면 더 포근해질 거야.").font(.footnote).foregroundStyle(FocusStyle.muted)
                    Button("내 방에 놓기", action: claimReward).buttonStyle(FocusPrimaryButton()).disabled(session.record.rewardIDs.isEmpty)
                }.padding(FocusStyle.inset)
            }.background(FocusStyle.canvas).foregroundStyle(FocusStyle.ink).navigationTitle("솜뭉치의 선물")
                .toolbar { Button("닫기") { showingReward = false } }
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
        session.claim(id); showingReward = false
    }
}

private struct FocusSettingsView: View {
    @State var focus: Int
    @State var rest: Int
    let start: (Int, Int) -> Void
    @State private var custom = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("집중 시간 설정").font(.title2.bold())
                    Text("집중하는 동안, 솜뭉치도 소품을 만들어요.").font(.caption).foregroundStyle(FocusStyle.muted)
                }
                Text("집중 시간").font(.caption).foregroundStyle(FocusStyle.muted)
                Stepper("\(focus)분", value: $focus, in: 1...180, step: 5).font(.headline).padding(Spacing.s)
                    .background(FocusStyle.canvas, in: RoundedRectangle(cornerRadius: 14))
                Text("쉬는 시간").font(.caption).foregroundStyle(FocusStyle.muted)
                if custom { Stepper("\(rest)분", value: $rest, in: 1...60) }
                else { Text("\(focus)분 집중 후 · \(rest)분 휴식").font(.footnote).frame(maxWidth: .infinity).padding(Spacing.s).background(FocusStyle.canvas, in: RoundedRectangle(cornerRadius: 14)) }
                HStack(spacing: Spacing.xs) {
                    preset("25 / 5", selected: !custom && focus == 25 && rest == 5) { focus = 25; rest = 5; custom = false }
                    preset("50 / 10", selected: !custom && focus == 50 && rest == 10) { focus = 50; rest = 10; custom = false }
                    preset("직접 설정", selected: custom) { custom = true }
                }
                Button("함께 시작하기") { start(focus, rest) }.buttonStyle(FocusPrimaryButton())
                Text("오늘 누적 시간은 그대로 이어져요.").font(.caption).foregroundStyle(FocusStyle.muted).frame(maxWidth: .infinity)
            }.padding(FocusStyle.inset)
        }.background(FocusStyle.paper).foregroundStyle(FocusStyle.ink)
    }
    private func preset(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action).font(.caption).frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(selected ? .white : FocusStyle.ink)
            .background(selected ? FocusStyle.ink : FocusStyle.canvas, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview { FocusFlowView().modelContainer(.preview) }
