# MacDirStat

Native macOS disk usage visualizer. Scans directories and displays file sizes in a tree view with plans for squarified treemap visualization.

**Status**: Work in progress. Currently supports directory scanning with a tree view sidebar.

## Requirements

- macOS 26 (Tahoe) or later
- Swift 6.2+ (Command Line Tools or Xcode)

## Build & Run

```bash
make build   # compile
make run     # compile and launch
make test    # run tests
make clean   # clean build artifacts
```

Or directly with Swift Package Manager:

```bash
swift build
swift run MacDirStat
```

## License

BSD-3-Clause
