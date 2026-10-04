import ARKit
import AVFoundation
import RealityKit
import SwiftUI

/// 카메라 화면에 인형을 놓고 함께 찍는 예절샷. 저장 버튼을 누르기 전에는 사진이 기기에 남지 않는다.
struct ARCaptureView: View {
    let dollImage: UIImage
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var shutterCount = 0
    @State private var photo: UIImage?

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.app.background)
                .navigationTitle("AR로 함께하기")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("닫기", systemImage: "xmark") { dismiss() }
                }
        }
        .onAppear { appState.isShowingAR = true }
        .onDisappear { appState.isShowingAR = false }
    }

    @ViewBuilder
    private var content: some View {
        if !ARWorldTrackingConfiguration.isSupported {
            NoticeCard(symbol: "camera.metering.unknown", title: "이 기기에서는 AR을 쓸 수 없어요",
                       message: "AR을 지원하는 iPhone에서 다시 열어 주세요")
        } else if let photo {
            CapturedPhotoView(photo: photo) { self.photo = nil }
        } else {
            switch cameraStatus {
            case .authorized:
                camera
            case .notDetermined:
                ProgressView()
                    .task {
                        _ = await AVCaptureDevice.requestAccess(for: .video)
                        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    }
            default:
                NoticeCard(symbol: "camera", title: "카메라를 쓸 수 없어요",
                           message: "설정에서 카메라 접근을 허용하면 인형과 함께 찍을 수 있어요",
                           actionTitle: "설정 열기") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        }
    }

    private var camera: some View {
        ARDollCamera(dollImage: dollImage, shutterCount: shutterCount) { photo = $0 }
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .top) {
                Text("바닥을 비춘 뒤 원하는 곳을 탭해 인형을 놓으세요")
                    .font(.footnote.bold())
                    .foregroundStyle(Color.app.surface)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.app.ink.opacity(0.8), in: Capsule())
                    .padding(.top, Spacing.xs)
            }
            .overlay(alignment: .bottom) {
                Button {
                    shutterCount += 1
                } label: {
                    Circle()
                        .fill(Color.app.surface)
                        .stroke(Color.app.accent, lineWidth: 6)
                        .frame(width: 76, height: 76)
                }
                .accessibilityLabel("촬영")
                .padding(.bottom, Spacing.xl)
            }
            .sensoryFeedback(.impact, trigger: shutterCount)
    }
}

private struct CapturedPhotoView: View {
    let photo: UIImage
    let onRetake: () -> Void
    @State private var isSaved = false

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .frame(maxHeight: .infinity)
            if isSaved {
                Label("사진에 저장했어요", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
            }
            HStack(spacing: Spacing.s) {
                Button("다시 찍기", action: onRetake)
                    .buttonStyle(.secondary)
                Button(isSaved ? "저장됨" : "저장") {
                    UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
                    isSaved = true
                }
                .buttonStyle(.secondary)
                .disabled(isSaved)
                ShareLink(item: Image(uiImage: photo), preview: SharePreview("예절샷", image: Image(uiImage: photo))) {
                    Text("공유")
                }
                .buttonStyle(.primary)
            }
        }
        .padding(Spacing.m)
        .sensoryFeedback(.success, trigger: isSaved)
    }
}

/// AR 카메라. 탭한 바닥에 인형을 세우고, shutterCount가 바뀌면 카메라 화면과 인형만 찍는다.
private struct ARDollCamera: UIViewRepresentable {
    let dollImage: UIImage
    let shutterCount: Int
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        view.session.run(configuration)

        let coaching = ARCoachingOverlayView()
        coaching.session = view.session
        coaching.goal = .horizontalPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(coaching)

        context.coordinator.view = view
        context.coordinator.dollImage = dollImage
        context.coordinator.lastShutter = shutterCount
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap)))
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        guard shutterCount != context.coordinator.lastShutter else { return }
        context.coordinator.lastShutter = shutterCount
        view.snapshot(saveToHDR: false) { image in
            if let image { onCapture(image) }
        }
    }

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        view.session.pause()
    }

    final class Coordinator: NSObject {
        weak var view: ARView?
        var dollImage = UIImage()
        var lastShutter = 0
        private var doll: Entity?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view,
                  let result = view.raycast(from: gesture.location(in: view), allowing: .estimatedPlane, alignment: .horizontal).first
            else { return }
            let position = Transform(matrix: result.worldTransform).translation
            let toCamera = view.cameraTransform.translation - position
            let facing = simd_quatf(angle: atan2(toCamera.x, toCamera.z), axis: [0, 1, 0])
            if let doll {
                doll.position = position
                doll.orientation = facing
                return
            }
            Task {
                let state = DollState(id: UUID(), name: "", imageData: dollImage.pngData() ?? Data(), filling: .fluffy, position: position)
                let doll = await SceneFactory.doll(state)
                doll.orientation = facing
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(doll)
                view.scene.addAnchor(anchor)
                self.doll = doll
            }
        }
    }
}

#Preview {
    ARCaptureView(dollImage: Doll.sample.image)
        .environment(AppState())
}
