import Foundation

public protocol FileSystemWatching: Sendable {
    func start(paths: [String], handler: @escaping @Sendable ([String]) -> Void)
    func stop()
}

public final class FSEventWatcher: FileSystemWatching, @unchecked Sendable {
    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "la.lex.macdirstat.fswatcher")
    private let debounceInterval: TimeInterval
    private var handler: (@Sendable ([String]) -> Void)?
    private var pendingPaths: Set<String> = []
    private var debounceWork: DispatchWorkItem?
    private var retainedSelf: Unmanaged<FSEventWatcher>?

    public init(debounceInterval: TimeInterval = 0.5) {
        self.debounceInterval = debounceInterval
    }

    public func start(paths: [String], handler: @escaping @Sendable ([String]) -> Void) {
        queue.sync {
            stopInternal()
            self.handler = handler
        }

        // Retain self so deinit cannot happen while stream is active
        let retained = Unmanaged.passRetained(self)

        var context = FSEventStreamContext()
        context.info = retained.toOpaque()

        let callback: FSEventStreamCallback = {
            _, clientInfo, numEvents, eventPaths, _, _ in
            guard let clientInfo = clientInfo else { return }
            let watcher = Unmanaged<FSEventWatcher>.fromOpaque(clientInfo).takeUnretainedValue()
            let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue()
                as! [String]
            watcher.handleEvents(paths: Array(paths.prefix(numEvents)))
        }

        let pathsToWatch = paths as CFArray
        let newStream = FSEventStreamCreate(
            nil, callback, &context, pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents))

        queue.sync {
            self.retainedSelf = retained
            self.stream = newStream
            if let stream = newStream {
                FSEventStreamSetDispatchQueue(stream, self.queue)
                FSEventStreamStart(stream)
            }
        }
    }

    private func handleEvents(paths: [String]) {
        // Already on self.queue (set via FSEventStreamSetDispatchQueue)
        pendingPaths.formUnion(paths)
        debounceWork?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let paths = Array(self.pendingPaths)
            self.pendingPaths.removeAll()
            self.handler?(paths)
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    public func stop() {
        queue.sync { stopInternal() }
    }

    private func stopInternal() {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        handler = nil
        debounceWork?.cancel()
        debounceWork = nil
        pendingPaths.removeAll()

        // Release the retained self — balances passRetained in start()
        retainedSelf?.release()
        retainedSelf = nil
    }

    deinit {
        // At this point no callbacks can fire because either:
        // - stop() was called (released retainedSelf, stream invalidated)
        // - start() was never called (no stream exists)
        // Direct call is safe since no concurrent access is possible.
        stopInternal()
    }
}
