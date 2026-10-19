import ARKit
import AVFoundation
import AVKit
import RealityKit
import ReplayKit
import SwiftUI

/// 카메라 화면에 인형을 놓고 함께 찍는 예절샷(사진·영상). 저장 버튼을 누르기 전에는 기기에 남지 않는다.
struct ARCaptureView: View {
    let doll: Doll
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var shutterCount = 0
    @State private var photo: UIImage?
    @State private var video: URL?
    @State private var isVideoMode = false
    @State private var isRecording = false
    @State private var isRecordFailed = false
    @State private var failure: String?
    @State private var isChoosingDance = false
    @State private var move = DanceMove.bounce
    @State private var hasDoll = false
    @State private var removeCount = 0

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background { AppBackground() }
                .navigationTitle("AR로 함께하기")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(isRecording ? .hidden : .automatic, for: .navigationBar)
                .alert("녹화하지 못했어요", isPresented: $isRecordFailed) {
                    Button("확인") {}
                } message: {
                    Text("화면 녹화를 허용했는지 확인하고 다시 해보세요")
                }
                .toolbar {
                    Button("닫기", systemImage: "xmark") { dismiss() }
                }
        }
        .onDisappear { appState.isShowingAR = false }
    }

    @ViewBuilder
    private var content: some View {
        if !ARWorldTrackingConfiguration.isSupported {
            NoticeCard(symbol: "camera.metering.unknown", title: "이 기기에서는 AR을 쓸 수 없어요",
                       message: "AR을 지원하는 iPhone에서 다시 열어 주세요")
        } else if let failure {
            NoticeCard(symbol: "camera.badge.ellipsis", title: "카메라를 켜지 못했어요",
                       message: "앱을 다시 열어 주세요\n\(failure)")
        } else if let video {
            CapturedVideoView(url: video) { self.video = nil }
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
        ARDollCamera(dollImage: doll.image, shutterCount: shutterCount, removeCount: removeCount, dance: isChoosingDance ? move : doll.dance,
                     onCapture: { photo = $0 }, onFail: { failure = $0 }, onPlaced: { hasDoll = $0 })
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .top) {
                if !isRecording {
                    HintCapsule(text: hasDoll ? "끌어서 옮기고, 두 손가락으로 크기를 바꿔요" : "바닥을 비춘 뒤 원하는 곳을 탭해 인형을 놓으세요", isLight: true)
                        .padding(.top, Spacing.xs)
                }
            }
            .overlay(alignment: .bottom) {
                if isChoosingDance {
                    DancePanel(doll: doll, selected: $move) {
                        withAnimation(.spring) { isChoosingDance = false }
                    }
                    .transition(.move(edge: .bottom))
                } else {
                    controls
                }
            }
            .sensoryFeedback(.impact, trigger: shutterCount)
            .sensoryFeedback(.impact, trigger: removeCount)
            .sensoryFeedback(.impact, trigger: isRecording)
    }

    /// 가운데 셔터, 왼쪽 춤추기, 오른쪽 인형 삭제. 녹화 중에는 셔터만 남긴다.
    private var controls: some View {
        VStack(spacing: Spacing.s) {
            if !isRecording {
                HStack(spacing: Spacing.xs) {
                    Chip(title: "사진", isSelected: !isVideoMode) { isVideoMode = false }
                    Chip(title: "영상", isSelected: isVideoMode) { isVideoMode = true }
                }
            }
            HStack(spacing: Spacing.s) {
                Group {
                    if hasDoll && !isRecording {
                        Button {
                            move = doll.dance ?? .bounce
                            withAnimation(.spring) { isChoosingDance = true }
                        } label: {
                            Label("춤추기", systemImage: "music.note")
                                .minimumScaleFactor(0.8)
                        }
                        .buttonStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                shutter
                Group {
                    if hasDoll && !isRecording {
                        Button("인형 삭제") { removeCount += 1 }
                            .appFont(.headline)
                            .foregroundStyle(Color.app.surface)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Color.app.danger, in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Spacing.m)
        }
        .padding(.bottom, Spacing.xl)
    }

    private var shutter: some View {
        Button {
            if isVideoMode {
                Task { await toggleRecording() }
            } else {
                shutterCount += 1
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.app.surface)
                    .stroke(Color.app.accent, lineWidth: 6)
                    .frame(width: 76, height: 76)
                if isVideoMode {
                    RoundedRectangle(cornerRadius: isRecording ? 8 : 26, style: .continuous)
                        .fill(Color.app.danger)
                        .frame(width: isRecording ? 28 : 52, height: isRecording ? 28 : 52)
                }
            }
            .animation(.spring, value: isRecording)
        }
        .accessibilityLabel(isVideoMode ? (isRecording ? "녹화 멈추기" : "녹화 시작") : "촬영")
    }

    private func toggleRecording() async {
        let recorder = RPScreenRecorder.shared()
        do {
            if isRecording {
                let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
                try await recorder.stopRecording(withOutput: url)
                isRecording = false
                video = url
            } else {
                try await recorder.startRecording()
                isRecording = true
            }
        } catch {
            isRecording = false
            isRecordFailed = true
        }
    }
}

private struct CapturedVideoView: View {
    let url: URL
    let onRetake: () -> Void
    @State private var player: AVPlayer
    @State private var isSaved = false

    init(url: URL, onRetake: @escaping () -> Void) {
        self.url = url
        self.onRetake = onRetake
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VStack(spacing: Spacing.m) {
            VideoPlayer(player: player)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .frame(maxHeight: .infinity)
            if isSaved {
                Label("사진에 저장했어요", systemImage: "checkmark.circle.fill")
                    .appFont(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
            }
            HStack(spacing: Spacing.s) {
                Button("다시 찍기", action: onRetake)
                    .buttonStyle(.secondary)
                Button(isSaved ? "저장됨" : "저장") {
                    UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
                    isSaved = true
                }
                .buttonStyle(.secondary)
                .disabled(isSaved)
                ShareLink(item: url) {
                    Text("공유")
                }
                .buttonStyle(.primary)
            }
        }
        .padding(Spacing.m)
        .onAppear { player.play() }
        .sensoryFeedback(.success, trigger: isSaved)
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
                    .appFont(.footnote)
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
    let removeCount: Int
    let dance: DanceMove?
    let onCapture: (UIImage) -> Void
    let onFail: (String) -> Void
    let onPlaced: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFail: onFail, onPlaced: onPlaced) }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        view.environment.background = .cameraFeed()
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        view.session.delegate = context.coordinator
        view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        let coaching = ARCoachingOverlayView()
        coaching.session = view.session
        coaching.goal = .horizontalPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(coaching)

        context.coordinator.view = view
        context.coordinator.dollImage = dollImage
        context.coordinator.lastShutter = shutterCount
        context.coordinator.lastRemove = removeCount
        context.coordinator.dance = dance
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap)))
        view.addGestureRecognizer(UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan)))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch)))
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        if removeCount != context.coordinator.lastRemove {
            context.coordinator.lastRemove = removeCount
            context.coordinator.removeDoll()
        }
        context.coordinator.setDance(dance)
        guard shutterCount != context.coordinator.lastShutter else { return }
        context.coordinator.lastShutter = shutterCount
        view.snapshot(saveToHDR: false) { image in
            if let image { onCapture(image) }
        }
    }

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        view.session.pause()
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        let onFail: (String) -> Void
        let onPlaced: (Bool) -> Void
        weak var view: ARView?
        var dollImage = UIImage()
        var lastShutter = 0
        var lastRemove = 0
        private var pinchBase: Float = 1
        var dance: DanceMove?
        private var bodyRest: Transform?
        private var doll: Entity?

        init(onFail: @escaping (String) -> Void, onPlaced: @escaping (Bool) -> Void) {
            self.onFail = onFail
            self.onPlaced = onPlaced
        }

        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
            let message = (error as NSError).localizedDescription + " (\((error as NSError).code))"
            Task { @MainActor in onFail(message) }
        }

        /// 몸통만 움직여서, 인형을 옮기거나 키워도 춤이 끊기지 않는다.
        func setDance(_ new: DanceMove?) {
            dance = new
            guard let body = doll?.findEntity(named: "body") else { return }
            let rest = bodyRest ?? body.transform
            bodyRest = rest
            body.stopAllAnimations()
            body.transform = rest
            if let new { SceneFactory.play(new, on: body) }
        }

        func removeDoll() {
            doll?.parent?.removeFromParent()
            doll = nil
            bodyRest = nil
            onPlaced(false)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let doll, let view,
                  let result = view.raycast(from: gesture.location(in: view), allowing: .estimatedPlane, alignment: .horizontal).first
            else { return }
            let position = Transform(matrix: result.worldTransform).translation
            let toCamera = view.cameraTransform.translation - position
            doll.position = position
            doll.orientation = simd_quatf(angle: atan2(toCamera.x, toCamera.z), axis: [0, 1, 0])
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let doll else { return }
            if gesture.state == .began { pinchBase = doll.scale.x }
            doll.scale = SIMD3(repeating: min(3, max(0.3, pinchBase * Float(gesture.scale))))
        }

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
                setDance(dance)
                onPlaced(true)
            }
        }
    }
}

#Preview {
    ARCaptureView(doll: .sample)
        .environment(AppState())
}
