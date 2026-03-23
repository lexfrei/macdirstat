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

    public init(debounceInterval: TimeInterval = 0.5) {
        self.debounceInterval = debounceInterval
    }

    public func start(paths: [String], handler: @escaping @Sendable ([String]) -> Void) {
        stop()
        self.handler = handler

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let callback: FSEventStreamCallback = {
            _, clientInfo, numEvents, eventPaths, _, _ in
            guard let clientInfo = clientInfo else { return }
            let watcher = Unmanaged<FSEventWatcher>.fromOpaque(clientInfo).takeUnretainedValue()
            let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue()
                as! [String]
            watcher.handleEvents(paths: Array(paths.prefix(numEvents)))
        }

        let pathsToWatch = paths as CFArray
        stream = FSEventStreamCreate(
            nil, callback, &context, pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents))

        if let stream = stream {
            FSEventStreamSetDispatchQueue(stream, queue)
            FSEventStreamStart(stream)
        }
    }

    private func handleEvents(paths: [String]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.pendingPaths.formUnion(paths)
            self.debounceWork?.cancel()

            let work = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                let paths = Array(self.pendingPaths)
                self.pendingPaths.removeAll()
                self.handler?(paths)
            }
            self.debounceWork = work
            self.queue.asyncAfter(deadline: .now() + self.debounceInterval, execute: work)
        }
    }

    public func stop() {
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
    }

    deinit {
        stop()
    }
}
