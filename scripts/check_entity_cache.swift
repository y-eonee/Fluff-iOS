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
        let budget = EntityTemplateCache<String>(capacity: 10, byteLimit: 10)
        var budgetBuilds = 0
        let make: @MainActor () async -> Entity = { budgetBuilds += 1; return Entity() }
        _ = await budget.entity(for: "a", estimatedCost: 6, build: make)
        _ = await budget.entity(for: "b", estimatedCost: 6, build: make)
        precondition(budget.estimatedBytes == 6)
        _ = await budget.entity(for: "a", estimatedCost: 6, build: make)
        precondition(budgetBuilds == 3, "Byte pressure must evict even below count limit")
        _ = await budget.entity(for: "oversized", estimatedCost: 20, build: make)
        _ = await budget.entity(for: "oversized", estimatedCost: 20, build: make)
        precondition(budgetBuilds == 5, "Oversized results must not be retained")
        budget.removeAll()
        precondition(budget.estimatedBytes == 0)
        _ = await budget.entity(for: "a", estimatedCost: 6, build: make)
        precondition(budgetBuilds == 6)
        let pending = Task { await budget.entity(for: "pending", estimatedCost: 4) {
            try? await Task.sleep(for: .milliseconds(50))
            return Entity()
        } }
        await Task.yield()
        budget.removeAll()
        _ = await pending.value
        precondition(budget.estimatedBytes == 0, "An in-flight build must not repopulate a purged cache")
        print("PASS: byte budget, oversized bypass, purge and in-flight purge")
        print("PASS: coalesced builds, independent clones, LRU eviction, configuration changes")
    }
}
