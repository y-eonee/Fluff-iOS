import Foundation
import Metal
import MetalPerformanceShaders
import RealityKit

/// A restrained halo around lit fleece, confined to the 3D render (not the UI).
nonisolated final class CozyBloom {
    private final class PipelineCache: @unchecked Sendable {
        let lock = NSLock()
        var values: [String: (MTLComputePipelineState, MTLComputePipelineState, MTLComputePipelineState)] = [:]
        func get(device: MTLDevice, preset: Bool) -> (MTLComputePipelineState, MTLComputePipelineState, MTLComputePipelineState)? {
            lock.lock(); defer { lock.unlock() }
            let key = "\(device.registryID)-\(preset)"
            if let value = values[key] { return value }
            guard let library = device.makeDefaultLibrary(),
                  let first = library.makeFunction(name: preset ? "plushExtractLight" : "cozyExtractLight"),
                  let second = library.makeFunction(name: preset ? "plushCompositeLight" : "cozyCompositeLight"),
                  let extract = try? device.makeComputePipelineState(function: first),
                  let composite = try? device.makeComputePipelineState(function: second),
                  let copyFunction = library.makeFunction(name: "cozyCopyColor"),
                  let copy = try? device.makeComputePipelineState(function: copyFunction) else { return nil }
            let value = (extract, composite, copy)
            values[key] = value
            return value
        }
    }
    private static let pipelines = PipelineCache()
    private let extract: MTLComputePipelineState
    private let composite: MTLComputePipelineState
    private let copy: MTLComputePipelineState
    private let device: MTLDevice
    private var highlights: MTLTexture?
    private var softened: MTLTexture?
    private var blur: MPSImageGaussianBlur?

    init?(device: MTLDevice, preset: Bool = false) {
        guard let (extract, composite, copy) = Self.pipelines.get(device: device, preset: preset) else { return nil }
        self.device = device
        self.extract = extract
        self.composite = composite
        self.copy = copy
    }

    func render(_ context: ARView.PostProcessContext) {
        render(source: context.sourceColorTexture, target: context.targetColorTexture, commandBuffer: context.commandBuffer)
    }

    func render(source: MTLTexture, target: MTLTexture, commandBuffer: MTLCommandBuffer) {
        let width = max(1, (source.width + 3) / 4)
        let height = max(1, (source.height + 3) / 4)
        if highlights?.width != width || highlights?.height != height {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--render-audit") {
                let summary = "source=\(source.width)x\(source.height) bloom=\(width)x\(height) buffers=\(width * height * 8 * 2) bytes"
                try? summary.write(to: URL.documentsDirectory.appending(path: "render-targets.txt"), atomically: true, encoding: .utf8)
            }
            #endif
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
            // Renderer outputs may be HDR while the drawable is BGRA/sRGB.
            // A compute copy converts formats; a Metal blit cannot do that.
            encode(copy, textures: [source, target], commandBuffer: commandBuffer)
            return
        }
        encode(extract, textures: [source, highlights], commandBuffer: commandBuffer)
        blur.encode(commandBuffer: commandBuffer, sourceTexture: highlights, destinationTexture: softened)
        encode(composite, textures: [source, softened, target], commandBuffer: commandBuffer)
    }

    private func encode(_ pipeline: MTLComputePipelineState, textures: [MTLTexture], commandBuffer: MTLCommandBuffer) {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.setComputePipelineState(pipeline)
        for (index, texture) in textures.enumerated() { encoder.setTexture(texture, index: index) }
        let width = pipeline.threadExecutionWidth
        guard let target = textures.last else { encoder.endEncoding(); return }
        encoder.dispatchThreads(MTLSize(width: target.width, height: target.height, depth: 1),
            threadsPerThreadgroup: MTLSize(width: width, height: min(8, pipeline.maxTotalThreadsPerThreadgroup / width), depth: 1))
        encoder.endEncoding()
    }
}
