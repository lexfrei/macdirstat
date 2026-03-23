TESTING_FW := $(shell xcode-select --print-path)/Library/Developer/Frameworks
SWIFT_TEST_FLAGS = -Xswiftc -F -Xswiftc $(TESTING_FW) \
	-Xlinker -F -Xlinker $(TESTING_FW) \
	-Xlinker -rpath -Xlinker $(TESTING_FW)

.PHONY: build test run clean

build:
	swift build

test:
	swift test $(SWIFT_TEST_FLAGS)

run:
	swift run MacDirStat

clean:
	swift package clean
