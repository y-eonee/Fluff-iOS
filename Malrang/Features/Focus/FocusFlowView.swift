import SwiftData
import SwiftUI

struct FocusFlowView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Query(sort: \Doll.createdAt) var dolls: [Doll]
    @State var session = FocusSession()
    @State var selection: UUID?
    @State var showMain = false
    @State var creating = false
    @State var confirmingExit = false
    @State var showingSettings = false
    @State var customTime = false
    @State var happyUntil = Date.distantPast
    @State var touchCount = 0
    let roomSnapshot: UIImage?

    init(session: FocusSession = FocusSession(), showMain: Bool = false, roomSnapshot: UIImage? = nil) {
        self.roomSnapshot = roomSnapshot
        _session = State(initialValue: session)
        _showMain = State(initialValue: showMain)
    }
    var selected: Doll? { dolls.first { $0.id == session.record.dollID } }

    var body: some View {
        NavigationStack {
            Group {
                if session.active { running }
                else if showingSettings, let selected { settingsSummary(selected) }
                else if showMain, let selected { main(selected) }
                else { selectionScreen }
            }
            .foregroundStyle(FocusStyle.ink)
            .background(FocusStyle.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSettings) { settingsSheet }
            .overlay { if confirmingExit { exitDialog } }
            .task {
                if session.active, selected == nil { session.stop() }
                while !Task.isCancelled {
                    session.tick()
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                }
            }
            .onChange(of: scenePhase) { if scenePhase == .active { session.tick() } }
            .sensoryFeedback(.impact(weight: .light), trigger: touchCount)
            .task(id: happyUntil) {
                guard happyUntil > .now else { return }
                do { try await Task.sleep(for: .seconds(max(0, happyUntil.timeIntervalSinceNow))) } catch { return }
                happyUntil = .distantPast
            }
        }
    }

    func header(action: @escaping () -> Void) -> some View {
        Text("focus together").notCliche(28, relativeTo: .title).tracking(-1.12)
            .frame(maxWidth: .infinity).frame(height: 44)
            .overlay(alignment: .leading) {
                Button(action: action) { D1Icon(name: "back").frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityLabel("뒤로")
            }.padding(.horizontal, 20)
    }

    var exitDialog: some View {
        ZStack {
            Color.mib.text.primary.opacity(0.28).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("집중 화면에서 나갈까요?").pretendard(.bold, 21)
                Text("지금까지의 집중 시간은 기록에 남아요.\n나가면 집중 메인으로 돌아가요.")
                    .pretendard(.medium, 13).foregroundStyle(FocusStyle.muted)
                HStack(spacing: 10) {
                    Button("나가기") { session.stop(); showMain = true; confirmingExit = false }
                        .buttonStyle(FocusCompactButton())
                    Button("머무르기") { confirmingExit = false }
                        .buttonStyle(FocusCompactButton(primary: true))
                }
            }.padding(22).focusPanel().padding(.horizontal, 22)
                .accessibilityAddTraits(.isModal)
        }.accessibilityAction(.escape) { confirmingExit = false }
    }
}

struct FocusCompactButton: ButtonStyle {
    var primary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.pretendard(.bold, 16)
            .foregroundStyle(primary ? Color.mib.text.onPrimary : FocusStyle.ink)
            .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
            .background(primary ? FocusStyle.sage : FocusStyle.paper, in: Capsule())
            .overlay(Capsule().strokeBorder(primary ? Color.clear : Color.mib.line.selected, lineWidth: 1.4))
    }
}

extension View {
    func focusPanel() -> some View {
        background {
            RoundedRectangle(cornerRadius: 20).fill(Color.mib.bg.surface.opacity(0.85))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }.overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.mib.text.onPrimary.opacity(0.7)))
        .foregroundStyle(Color.mib.text.primary)
    }
}

#Preview { FocusFlowView().modelContainer(.preview) }
