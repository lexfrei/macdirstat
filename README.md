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
- Scan snapshots and diff engine (library-level, UI planned)
- File deletion (Move to Trash with confirmation)
- Multi-tab scanning with volume discovery
- Context menu: Reveal in Finder, Copy Path
- Stays on same volume (does not cross filesystem boundaries)
- Physical on-disk size (iCloud-evicted files show as 0 bytes — they occupy no local disk space)

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

Note: use `make test` instead of bare `swift test` — the Swift Testing framework in Command Line Tools requires explicit framework search paths provided by the Makefile.

## License

BSD-3-Clause
