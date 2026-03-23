# MacDirStat

Native macOS disk usage visualizer with squarified treemap. Scans directories and displays file sizes as colored rectangles where area is proportional to file size, colored by file extension.

**Status**: Work in progress. Directory scanning, treemap visualization, and extension legend are implemented. Interactivity (hover, click, drill-down) is next.

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
