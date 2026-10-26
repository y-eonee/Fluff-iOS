import RealityKit

/// Stores untouched templates, including in-flight builds. Callers always own a clone.
@MainActor
final class EntityTemplateCache<Key: Equatable> {
    private struct Entry {
        let key: Key
        let task: Task<Entity, Never>
        let cost: Int
    }
    private var entries: [Entry] = []
    private let capacity: Int
    private let byteLimit: Int
    var estimatedBytes: Int { entries.reduce(0) { $0 + $1.cost } }

    init(capacity: Int, byteLimit: Int = .max) {
        self.capacity = max(1, capacity)
        self.byteLimit = max(1, byteLimit)
    }

    func removeAll() { entries.removeAll() }

    func entity(for key: Key, estimatedCost: Int = 1, build: @escaping @MainActor () async -> Entity) async -> Entity {
        let task: Task<Entity, Never>
        if let index = entries.firstIndex(where: { $0.key == key }) {
            let entry = entries.remove(at: index)
            entries.append(entry)
            task = entry.task
        } else {
            task = Task { await build() }
            let cost = max(1, estimatedCost)
            // An oversized result is returned to its caller but never retained by the cache.
            if cost <= byteLimit {
                while !entries.isEmpty && (entries.count >= capacity || estimatedBytes > byteLimit - cost) {
                    entries.removeFirst()
                }
                entries.append(Entry(key: key, task: task, cost: cost))
            }
        }
        let template = await task.value
        return template.clone(recursive: true)
    }
}
