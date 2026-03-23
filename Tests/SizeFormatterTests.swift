import Testing

@testable import MacDirStatKit

@Suite("SizeFormatter")
struct SizeFormatterTests {
    @Test func zeroBytes() {
        #expect(SizeFormatter.format(0) == "0 B")
    }

    @Test func singleByte() {
        #expect(SizeFormatter.format(1) == "1 B")
    }

    @Test func bytes() {
        #expect(SizeFormatter.format(512) == "512 B")
        #expect(SizeFormatter.format(999) == "999 B")
    }

    @Test func kilobytes() {
        #expect(SizeFormatter.format(1000) == "1.0 KB")
        #expect(SizeFormatter.format(1500) == "1.5 KB")
        #expect(SizeFormatter.format(10000) == "10.0 KB")
    }

    @Test func megabytes() {
        #expect(SizeFormatter.format(1_000_000) == "1.0 MB")
        #expect(SizeFormatter.format(5_000_000) == "5.0 MB")
    }

    @Test func gigabytes() {
        #expect(SizeFormatter.format(1_000_000_000) == "1.0 GB")
        #expect(SizeFormatter.format(10_000_000_000) == "10.0 GB")
    }

    @Test func terabytes() {
        #expect(SizeFormatter.format(1_000_000_000_000) == "1.0 TB")
    }

    @Test func petabytes() {
        #expect(SizeFormatter.format(1_000_000_000_000_000) == "1.0 PB")
    }

    @Test func negativeValues() {
        #expect(SizeFormatter.format(-1) == "-1 B")
        #expect(SizeFormatter.format(-1500) == "-1.5 KB")
        #expect(SizeFormatter.format(-1_000_000) == "-1.0 MB")
    }

    @Test func fractionalDisplay() {
        #expect(SizeFormatter.format(1_500) == "1.5 KB")
        #expect(SizeFormatter.format(2_500_000) == "2.5 MB")
    }

    @Test func finderConsistency() {
        // Finder shows 1 GB = 1,000,000,000 bytes (SI base-10)
        #expect(SizeFormatter.format(1_000_000_000) == "1.0 GB")
    }
}
