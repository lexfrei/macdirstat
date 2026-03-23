import SwiftUI
import Testing

@testable import MacDirStatKit

private final class AtomicBool: @unchecked Sendable {
    private var _value: Bool
    private let lock = NSLock()

    init(_ value: Bool) { _value = value }

    var value: Bool {
        lock.withLock { _value }
    }

    func set(_ newValue: Bool) {
        lock.withLock { _value = newValue }
    }
}

private final class AtomicInt: @unchecked Sendable {
    private var _value: Int
    private let lock = NSLock()

    init(_ value: Int) { _value = value }

    var value: Int {
        lock.withLock { _value }
    }

    func increment() {
        lock.withLock { _value += 1 }
    }
}

@Suite("FSEventWatcher")
struct FSEventWatcherTests {
    private func createTempDir() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacDirStatWatch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test func watcherDetectsNewFile() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let watcher = FSEventWatcher(debounceInterval: 0.2)
        let fired = AtomicBool(false)

        watcher.start(paths: [dir.path(percentEncoded: false)]) { _ in
            fired.set(true)
        }

        try await Task.sleep(for: .milliseconds(200))
        try Data("test".utf8).write(to: dir.appendingPathComponent("new.txt"))

        try await Task.sleep(for: .seconds(1))
        watcher.stop()

        #expect(fired.value == true)
    }

    @Test func watcherDetectsFileDeletion() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let file = dir.appendingPathComponent("delete-me.txt")
        try Data("test".utf8).write(to: file)

        let watcher = FSEventWatcher(debounceInterval: 0.2)
        let fired = AtomicBool(false)

        watcher.start(paths: [dir.path(percentEncoded: false)]) { _ in
            fired.set(true)
        }

        try await Task.sleep(for: .milliseconds(200))
        try FileManager.default.removeItem(at: file)

        try await Task.sleep(for: .seconds(1))
        watcher.stop()

        #expect(fired.value == true)
    }

    @Test func stopPreventsCallbacks() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let watcher = FSEventWatcher(debounceInterval: 0.1)
        let callCount = AtomicInt(0)

        watcher.start(paths: [dir.path(percentEncoded: false)]) { _ in
            callCount.increment()
        }

        watcher.stop()
        try Data("test".utf8).write(to: dir.appendingPathComponent("after-stop.txt"))
        try await Task.sleep(for: .milliseconds(500))

        #expect(callCount.value == 0)
    }
}
