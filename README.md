# MacDirStat

Native macOS disk usage visualizer with squarified treemap. Scans directories and displays file sizes as colored rectangles where area is proportional to file size, colored by file extension.

## Features

- Recursive directory scanning with progress reporting
- Squarified treemap visualization with Canvas rendering
- Extension-based color mapping with golden angle distribution
- Hover highlighting and click selection
- Double-click drill-down with breadcrumb navigation
- Pinch-to-zoom and pan when zoomed in
- Directory tree sidebar with file sizes
- Extension legend with color indicators
- Real-time filesystem watching (FSEvents)
- Scan snapshots and comparison (diff added/removed/changed)
- File deletion (Move to Trash with confirmation)
- Multi-tab scanning with volume discovery
- Context menu: Reveal in Finder, Copy Path
- Stays on same volume (skips network mounts and external drives)
- Correct iCloud handling (shows physical on-disk size)

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

Create a standalone .app bundle:

```bash
./scripts/bundle-app.sh
open MacDirStat.app
```

## License

BSD-3-Clause
