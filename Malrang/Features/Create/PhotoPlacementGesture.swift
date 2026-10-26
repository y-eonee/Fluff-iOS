import SwiftUI

/// Keeps touch edits in the same draft values used by sliders and final rendering.
struct PhotoPlacementGesture: ViewModifier {
    let draft: DollDraft
    let isPreset: Bool
    var enabled = true
    @State private var lastTranslation = CGSize.zero
    @State private var lastMagnification: CGFloat = 1

    func body(content: Content) -> some View {
        content.overlay {
            if enabled {
                GeometryReader { geometry in
                    Color.clear.contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 3)
                            .onChanged { value in
                                let dx = (value.translation.width - lastTranslation.width) / max(1, geometry.size.width)
                                let dy = (value.translation.height - lastTranslation.height) / max(1, geometry.size.height)
                                if isPreset {
                                    draft.faceOffsetX = min(0.5, max(-0.5, draft.faceOffsetX - Float(dx * 3)))
                                    draft.faceOffsetY = min(0.5, max(-0.5, draft.faceOffsetY + Float(dy * 3)))
                                } else {
                                    draft.customOffset.width = min(0.4, max(-0.4, draft.customOffset.width + dx))
                                    draft.customOffset.height = min(0.4, max(-0.4, draft.customOffset.height + dy))
                                }
                                draft.snapshot = nil
                                lastTranslation = value.translation
                            }.onEnded { _ in lastTranslation = .zero }
                            .simultaneously(with: MagnifyGesture()
                                .onChanged { value in
                                    let factor = value.magnification / lastMagnification
                                    if isPreset { draft.faceScale = min(3, max(1, draft.faceScale * factor)) }
                                    else { draft.customScale = min(2, max(0.6, draft.customScale * factor)) }
                                    draft.snapshot = nil
                                    lastMagnification = value.magnification
                                }.onEnded { _ in lastMagnification = 1 }))
                        .accessibilityHidden(true)
                }
            }
        }
        .onChange(of: isPreset) { lastTranslation = .zero; lastMagnification = 1 }
    }
}

struct CustomPhotoPreview: View {
    let draft: DollDraft
    var body: some View {
        GeometryReader { geometry in
            DollArtwork(shape: .pillow, cutout: Image(uiImage: draft.finalCutout ?? draft.photo ?? UIImage()), faceScale: draft.customScale)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: draft.customOffset.width * geometry.size.width,
                        y: draft.customOffset.height * geometry.size.height)
        }.aspectRatio(0.8, contentMode: .fit).clipped()
    }
}
