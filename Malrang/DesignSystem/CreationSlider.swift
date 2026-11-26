import SwiftUI

/// UIKit permits the circular stitched thumb and blue remaining track in the Figma control.
struct CreationSlider: UIViewRepresentable {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let label: String
    var neutralValue: Float? = nil
    var neutralPosition: Float = 0.5
    private func position(for value: Float) -> Float {
        guard let neutralValue else { return (value - range.lowerBound) / (range.upperBound - range.lowerBound) }
        return value <= neutralValue
            ? (value - range.lowerBound) / (neutralValue - range.lowerBound) * neutralPosition
            : neutralPosition + (value - neutralValue) / (range.upperBound - neutralValue) * (1 - neutralPosition)
    }
    private func mappedValue(_ position: Float) -> Float {
        guard let neutralValue else { return range.lowerBound + position * (range.upperBound - range.lowerBound) }
        return position <= neutralPosition
            ? range.lowerBound + position / neutralPosition * (neutralValue - range.lowerBound)
            : neutralValue + (position - neutralPosition) / (1 - neutralPosition) * (range.upperBound - neutralValue)
    }
    func makeCoordinator() -> Coordinator { Coordinator(value: $value, map: mappedValue) }
    func makeUIView(context: Context) -> UISlider {
        let slider = SourceCreationSlider()
        slider.minimumTrackTintColor = UIColor(Color.rep4.c03)
        slider.maximumTrackTintColor = UIColor(Color.rep4.c21)
        let thumb = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { context in
            let circle = UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 18, height: 18))
            UIColor.white.setFill(); circle.fill()
            UIColor(Color.rep4.c03).setStroke(); circle.lineWidth = 1; circle.stroke()
        }
        slider.setThumbImage(thumb, for: .normal)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return slider
    }
    func updateUIView(_ slider: UISlider, context: Context) {
        context.coordinator.value = $value
        context.coordinator.map = mappedValue
        slider.minimumValue = 0; slider.maximumValue = 1
        slider.value = position(for: value); slider.accessibilityLabel = label
        slider.accessibilityValue = "\(Int(((value - range.lowerBound) / (range.upperBound - range.lowerBound) * 100).rounded()))"
    }
    final class Coordinator: NSObject {
        var value: Binding<Float>
        var map: (Float) -> Float
        init(value: Binding<Float>, map: @escaping (Float) -> Float) { self.value = value; self.map = map }
        @objc func changed(_ slider: UISlider) { value.wrappedValue = map(slider.value) }
    }
}

private final class SourceCreationSlider: UISlider {
    private var grabOffset: CGFloat = 0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Include the outside half of the thumb at both ends of the track.
        bounds.insetBy(dx: -22, dy: -max(0, (44 - bounds.height) / 2)).contains(point)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isEnabled else { return false }
        let point = touch.location(in: self)
        let track = trackRect(forBounds: bounds)
        let thumb = thumbRect(forBounds: bounds, trackRect: track, value: value)
        // Grabbing near the thumb must not jump the value under the finger.
        grabOffset = abs(point.x - thumb.midX) <= 22 ? point.x - thumb.midX : 0
        updateValue(at: point.x)
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateValue(at: touch.location(in: self).x)
        return true
    }

    private func updateValue(at x: CGFloat) {
        let track = trackRect(forBounds: bounds)
        let fraction = min(1, max(0, (x - grabOffset - track.minX) / max(1, track.width)))
        let next = minimumValue + Float(fraction) * (maximumValue - minimumValue)
        guard next != value else { return }
        value = next
        sendActions(for: .valueChanged)
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let track = super.trackRect(forBounds: bounds)
        return CGRect(x: track.minX, y: bounds.midY - 2.5, width: track.width, height: 5)
    }
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var thumb = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let fraction = CGFloat((value - minimumValue) / max(0.0001, maximumValue - minimumValue))
        thumb.origin.x = rect.minX + rect.width * fraction - thumb.width / 2
        return thumb
    }
}
