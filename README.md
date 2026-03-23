# MacDirStat

Native macOS disk usage visualizer with squarified treemap. Each file is a rectangle with area proportional to its size, colored by file extension.

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
