import Metal
import MetalPerformanceShaders
import RealityKit

/// A restrained halo around lit fleece, confined to the 3D render (not the UI).
nonisolated final class CozyBloom {
    private let extract: MTLComputePipelineState
    private let composite: MTLComputePipelineState
    private let device: MTLDevice
    private var highlights: MTLTexture?
    private var softened: MTLTexture?
    private var blur: MPSImageGaussianBlur?

    init?(device: MTLDevice, preset: Bool = false) {
        guard let library = device.makeDefaultLibrary(),
              let first = library.makeFunction(name: preset ? "plushExtractLight" : "cozyExtractLight"),
              let second = library.makeFunction(name: preset ? "plushCompositeLight" : "cozyCompositeLight"),
              let extract = try? device.makeComputePipelineState(function: first),
              let composite = try? device.makeComputePipelineState(function: second) else { return nil }
        self.device = device
        self.extract = extract
        self.composite = composite
    }

    func render(_ context: ARView.PostProcessContext) {
        let source = context.sourceColorTexture
        let width = max(1, (source.width + 1) / 2)
        let height = max(1, (source.height + 1) / 2)
        if highlights?.width != width || highlights?.height != height {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                width: width, height: height, mipmapped: false)
            descriptor.usage = [.shaderRead, .shaderWrite]
            descriptor.storageMode = .private
            highlights = device.makeTexture(descriptor: descriptor)
            softened = device.makeTexture(descriptor: descriptor)
            blur = MPSImageGaussianBlur(device: device, sigma: Float(width) / 150)
            blur?.edgeMode = .clamp
        }
        guard let highlights, let softened, let blur else {
            let encoder = context.commandBuffer.makeBlitCommandEncoder()
            encoder?.copy(from: source, to: context.targetColorTexture)
            encoder?.endEncoding()
            return
        }
        encode(extract, textures: [source, highlights], context: context)
        blur.encode(commandBuffer: context.commandBuffer, sourceTexture: highlights, destinationTexture: softened)
        encode(composite, textures: [source, softened, context.targetColorTexture], context: context)
    }

    private func encode(_ pipeline: MTLComputePipelineState, textures: [MTLTexture], context: ARView.PostProcessContext) {
        guard let encoder = context.commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.setComputePipelineState(pipeline)
        for (index, texture) in textures.enumerated() { encoder.setTexture(texture, index: index) }
        let width = pipeline.threadExecutionWidth
        guard let target = textures.last else { encoder.endEncoding(); return }
        encoder.dispatchThreads(MTLSize(width: target.width, height: target.height, depth: 1),
            threadsPerThreadgroup: MTLSize(width: width, height: min(8, pipeline.maxTotalThreadsPerThreadgroup / width), depth: 1))
        encoder.endEncoding()
    }
}
