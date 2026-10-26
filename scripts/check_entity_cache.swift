import RealityKit
import Foundation

@main
struct CheckEntityCache {
    @MainActor static func main() async {
        let cache = EntityTemplateCache<String>(capacity: 2)
        var builds = 0
        let build: @MainActor () async -> Entity = {
            builds += 1
            await Task.yield()
            let root = Entity()
            let part = Entity(); part.name = "part"; root.addChild(part)
            return root
        }
        let first = Task { await cache.entity(for: "cat", build: build) }
        let second = Task { await cache.entity(for: "cat", build: build) }
        let a = await first.value, b = await second.value
        precondition(builds == 1, "Concurrent requests must share one build")
        a.findEntity(named: "part")?.position.x = 9
        precondition(b.findEntity(named: "part")?.position.x == 0, "Clones must not share transforms")
        _ = await cache.entity(for: "bear", build: build)
        _ = await cache.entity(for: "cat", build: build)
        _ = await cache.entity(for: "rabbit", build: build)
        precondition(builds == 3)
        _ = await cache.entity(for: "bear", build: build)
        precondition(builds == 4, "Least recently used template must be evicted")
        _ = await cache.entity(for: "cat-with-photo", build: build)
        precondition(builds == 5, "Changed configuration must rebuild")
        print("PASS: coalesced builds, independent clones, LRU eviction, configuration changes")
    }
}
