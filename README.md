# MacDirStat

Native macOS disk usage visualizer with squarified treemap. Scans directories and displays file sizes as colored rectangles where area is proportional to file size, colored by file extension.

## Features

- Recursive directory scanning with progress reporting
- Squarified treemap visualization with Canvas rendering
- Extension-based color mapping with golden angle distribution
- Hover highlighting and click selection
- Double-click drill-down with breadcrumb navigation
- Directory tree sidebar with file sizes
- Extension legend with color indicators

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
