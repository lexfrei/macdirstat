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
    private var contextRef: Unmanaged<WatcherContext>?

    public init(debounceInterval: TimeInterval = 0.5) {
        self.debounceInterval = debounceInterval
    }

    public func start(paths: [String], handler: @escaping @Sendable ([String]) -> Void) {
        stop()

        let context = WatcherContext()
        context.onEvent = { [weak self] paths in
            self?.queue.async { self?.handleEventsInternal(paths: paths) }
        }

        let retained = Unmanaged.passRetained(context)

        var fsContext = FSEventStreamContext()
        fsContext.info = retained.toOpaque()

        let callback: FSEventStreamCallback = {
            _, clientInfo, numEvents, eventPaths, _, _ in
            guard let clientInfo = clientInfo else { return }
            let ctx = Unmanaged<WatcherContext>.fromOpaque(clientInfo).takeUnretainedValue()
            guard let cfPaths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue()
                as? [String]
            else { return }
            ctx.onEvent?(Array(cfPaths.prefix(numEvents)))
        }

        let pathsToWatch = paths as CFArray
        let newStream = FSEventStreamCreate(
            nil, callback, &fsContext, pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents))

        queue.sync {
            self.handler = handler
            self.contextRef = retained
            self.stream = newStream
            if let s = newStream {
                FSEventStreamSetDispatchQueue(s, self.queue)
                FSEventStreamStart(s)
            }
        }
    }

    private func handleEventsInternal(paths: [String]) {
        pendingPaths.formUnion(paths)
        debounceWork?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let collected = Array(self.pendingPaths)
            self.pendingPaths.removeAll()
            self.handler?(collected)
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    public func stop() {
        queue.sync { stopInternal() }
    }

    private func stopInternal() {
        if let s = stream {
            FSEventStreamStop(s)
            FSEventStreamInvalidate(s)
            FSEventStreamRelease(s)
        }
        stream = nil
        handler = nil
        debounceWork?.cancel()
        debounceWork = nil
        pendingPaths.removeAll()
        contextRef?.release()
        contextRef = nil
    }

    deinit {
        // queue.sync is unsafe in deinit (potential deadlock if deinit
        // happens on queue). Direct call is acceptable: at deinit time
        // no external references exist, so no new work can be enqueued.
        stopInternal()
    }
}

private final class WatcherContext: @unchecked Sendable {
    // Set once before FSEventStreamStart, read-only during callbacks
    var onEvent: (([String]) -> Void)?
}
