import SwiftData
import SwiftUI

struct FocusFlowView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Query(sort: \Doll.createdAt) var dolls: [Doll]
    @State var session: FocusSession
    @State var selection: UUID?
    @State var showMain = false
    @State var creating = false
    @State var confirmingExit = false
    @State var customTime = false
    @State var happyUntil = Date.distantPast
    @State var touchCount = 0
    let roomSnapshot: UIImage?

    init(session: FocusSession = FocusSession(), showMain: Bool = false, roomSnapshot: UIImage? = nil) {
        self.roomSnapshot = roomSnapshot
        _session = State(initialValue: session)
        _showMain = State(initialValue: showMain)
        #if DEBUG
        _confirmingExit = State(initialValue: ProcessInfo.processInfo.arguments.contains("--design-preview=exit"))
        #endif
    }
    var selected: Doll? { dolls.first { $0.id == session.record.dollID } }

    var body: some View {
        NavigationStack {
            Group {
                if session.active { running }
                else if showMain, let selected { main(selected) }
                else { selectionScreen }
            }
            .foregroundStyle(Color.rep4.c03)
            .background(FlowDesign.canvas.ignoresSafeArea())
            .environment(\.updatedFlowDesign, true)
            .toolbar(.hidden, for: .navigationBar)
            .overlay { if confirmingExit { exitDialog } }
            .task {
                if session.active, selected == nil { session.stop() }
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--preview-selection") { selection = session.record.dollID }
                #endif
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--focus-start-preview"), !session.active, let doll = dolls.first {
                    session.select(doll.id); session.confirmTime(); session.start()
                }
                #endif
                while !Task.isCancelled {
                    session.tick()
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                }
            }
            .onChange(of: session.active) { wasActive, active in
                if !wasActive, active, let selected {
                    DollActivityRecorder.record(.desk, ids: [selected.id], in: modelContext)
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

    /// Keep the same home snapshot through selection, focus, pause, and rest.
    var roomBackground: some View {
        GeometryReader { geometry in
            Group {
                if let roomSnapshot { Image(uiImage: roomSnapshot).resizable() }
                else { Image("rep4_home_room").resizable() }
            }.scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)

                .clipped()
        }.accessibilityHidden(true)
    }

    func header(action: @escaping () -> Void) -> some View {
        FlowHeader(title: "집중하기", onBack: action)
    }

    var exitDialog: some View {
        RepresentativeConfirmDialog(title: "집중 화면에서 나갈까요?", message: "지금까지의 집중 시간은 기록에 남아요.\n나가면 집중 메인으로 돌아가요.", onLeave: {
            session.stop(); showMain = true; confirmingExit = false
        }, onStay: { confirmingExit = false })
    }
}

struct FocusCompactButton: ButtonStyle {
    var primary = false
    var subdued = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(RepresentativeActionSurface(primary: primary, height: 44))
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
