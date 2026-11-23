import SwiftUI

/// November flow revisions: 1727:21870 / 1727:24810 / 1727:22870.
/// Kept separate from the original four-screen tokens used by room editing.
enum FlowDesign {
    static let canvas = Color(uiColor: Palette.uiColor("#ECEEEF"))
    static let makingCanvas = Color(uiColor: Palette.uiColor("#E5E5E4"))
    static let profileCanvas = Color(uiColor: Palette.uiColor("#EDF0F0"))
    static let headerHeight: CGFloat = 60
    static let header = Color(uiColor: Palette.uiColor("#FDFDFD"))
    static let blue = Color(uiColor: Palette.uiColor("#9CCDFF"))
    static let lightBlue = Color(uiColor: Palette.uiColor("#CFE6FF"))
    static let selectionBorder = Color(uiColor: Palette.uiColor("#94C9FF"))
    static let selected = LinearGradient(colors: [Color(uiColor: Palette.uiColor("#DCECFF")), Color(uiColor: Palette.uiColor("#B2D8FF"))], startPoint: .top, endPoint: .bottom)
    static let action = LinearGradient(stops: [.init(color: Color(uiColor: Palette.uiColor("#1C1A1A")), location: 0.32171), .init(color: Color(uiColor: Palette.uiColor("#353639")), location: 0.97364)], startPoint: .top, endPoint: .bottom)
    static let video = LinearGradient(stops: [.init(color: Color(uiColor: Palette.uiColor("#FAECDA")), location: 0), .init(color: Color(uiColor: Palette.uiColor("#A4D1FF")), location: 0.27129), .init(color: Color(uiColor: Palette.uiColor("#62AEFC")), location: 0.71429)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

private struct UpdatedFlowDesignKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var updatedFlowDesign: Bool {
        get { self[UpdatedFlowDesignKey.self] }
        set { self[UpdatedFlowDesignKey.self] = newValue }
    }
}

extension View {
    func flowPageTitle(_ title: String, isVisible: Bool = true) -> some View {
        modifier(FlowPageTitle(title: title, isVisible: isVisible))
    }
}

private struct FlowPageTitle: ViewModifier {
    let title: String
    let isVisible: Bool
    @State private var navigationBarHeight: CGFloat = 44

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FlowDesign.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).pretendard(.semiBold, 19, tracking: -0.76)
                        .offset(y: 2)
                        .foregroundStyle(Color.rep4.c10).accessibilityAddTraits(.isHeader)
                }
            }
            // Preserve native back/close actions while matching custom 60pt headers.
            .safeAreaInset(edge: .top, spacing: 0) {
                if isVisible {
                    FlowDesign.header
                        .frame(height: max(0, FlowDesign.headerHeight - navigationBarHeight))
                        .accessibilityHidden(true)
                }
            }
            .background(NavigationBarMeasurement(height: $navigationBarHeight))
            .environment(\.updatedFlowDesign, true)
    }
}

private struct NavigationBarMeasurement: UIViewControllerRepresentable {
    @Binding var height: CGFloat

    func makeUIViewController(context: Context) -> MeasurementController {
        let controller = MeasurementController()
        controller.onMeasure = { height = $0 }
        return controller
    }

    func updateUIViewController(_ controller: MeasurementController, context: Context) {
        controller.onMeasure = { height = $0 }
        controller.measure()
    }

    final class MeasurementController: UIViewController {
        var onMeasure: ((CGFloat) -> Void)?
        private var measuredHeight: CGFloat = 0

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            measure()
        }

        func measure() {
            guard let bar = navigationController?.navigationBar, !bar.isHidden,
                  bar.bounds.height > 0, bar.bounds.height != measuredHeight else { return }
            measuredHeight = bar.bounds.height
            let value = measuredHeight
            DispatchQueue.main.async { [weak self] in self?.onMeasure?(value) }
        }
    }
}

struct FlowHeader: View {
    let title: String
    var backLabel = "뒤로"
    var onBack: (() -> Void)? = nil
    var body: some View {
        Text(title).pretendard(.semiBold, 19, tracking: -0.76)
            .foregroundStyle(Color.rep4.c10)
            .frame(maxWidth: .infinity).frame(height: 44)
            .overlay(alignment: .leading) {
                if let onBack {
                    Button(action: onBack) {
                        D1Icon(name: "back").offset(y: 5).frame(width: 44, height: 44)
                    }.buttonStyle(.plain).accessibilityLabel(backLabel).padding(.leading, 18)
                }
            }
            .padding(.top, 2).frame(height: FlowDesign.headerHeight, alignment: .top)
            .background(FlowDesign.header.ignoresSafeArea(edges: .top))
    }
}
