import SwiftUI

/// UIKit permits the circular stitched thumb and blue remaining track in the Figma control.
struct CreationSlider: UIViewRepresentable {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let label: String
    func makeCoordinator() -> Coordinator { Coordinator(value: $value) }
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumTrackTintColor = Palette.uiColor("#6B4A3E")
        slider.maximumTrackTintColor = Palette.uiColor("#CFE8F2")
        let thumb = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { context in
            let circle = UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 18, height: 18))
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 2, color: UIColor.black.withAlphaComponent(0.15).cgColor)
            UIColor.white.setFill(); circle.fill()
            Palette.uiColor("#6B4A3E").setStroke(); circle.lineWidth = 2; circle.stroke()
        }
        slider.setThumbImage(thumb, for: .normal)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return slider
    }
    func updateUIView(_ slider: UISlider, context: Context) {
        context.coordinator.value = $value
        slider.minimumValue = range.lowerBound; slider.maximumValue = range.upperBound
        slider.value = value; slider.accessibilityLabel = label
        slider.accessibilityValue = "\(Int(((value - range.lowerBound) / (range.upperBound - range.lowerBound) * 100).rounded()))"
    }
    final class Coordinator: NSObject {
        var value: Binding<Float>
        init(value: Binding<Float>) { self.value = value }
        @objc func changed(_ slider: UISlider) { value.wrappedValue = slider.value }
    }
}
