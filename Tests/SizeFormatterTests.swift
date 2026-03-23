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
        #expect(SizeFormatter.format(1023) == "1023 B")
    }

    @Test func kilobytes() {
        #expect(SizeFormatter.format(1024) == "1.0 KB")
        #expect(SizeFormatter.format(1536) == "1.5 KB")
        #expect(SizeFormatter.format(10240) == "10.0 KB")
    }

    @Test func megabytes() {
        #expect(SizeFormatter.format(1_048_576) == "1.0 MB")
        #expect(SizeFormatter.format(5_242_880) == "5.0 MB")
    }

    @Test func gigabytes() {
        #expect(SizeFormatter.format(1_073_741_824) == "1.0 GB")
        #expect(SizeFormatter.format(10_737_418_240) == "10.0 GB")
    }

    @Test func terabytes() {
        #expect(SizeFormatter.format(1_099_511_627_776) == "1.0 TB")
    }

    @Test func petabytes() {
        #expect(SizeFormatter.format(1_125_899_906_842_624) == "1.0 PB")
    }

    @Test func negativeValues() {
        #expect(SizeFormatter.format(-1) == "0 B")
    }

    @Test func fractionalDisplay() {
        #expect(SizeFormatter.format(1_536) == "1.5 KB")
        #expect(SizeFormatter.format(2_621_440) == "2.5 MB")
    }
}
