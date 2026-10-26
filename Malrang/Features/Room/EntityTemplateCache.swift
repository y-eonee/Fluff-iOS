import RealityKit

/// Stores untouched templates, including in-flight builds. Callers always own a clone.
@MainActor
final class EntityTemplateCache<Key: Equatable> {
    private struct Entry {
        let key: Key
        let task: Task<Entity, Never>
    }
    private var entries: [Entry] = []
    private let capacity: Int

    init(capacity: Int) { self.capacity = max(1, capacity) }

    func entity(for key: Key, build: @escaping @MainActor () async -> Entity) async -> Entity {
        let task: Task<Entity, Never>
        if let index = entries.firstIndex(where: { $0.key == key }) {
            let entry = entries.remove(at: index)
            entries.append(entry)
            task = entry.task
        } else {
            task = Task { await build() }
            entries.append(Entry(key: key, task: task))
            if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
        }
        let template = await task.value
        return template.clone(recursive: true)
    }
}
