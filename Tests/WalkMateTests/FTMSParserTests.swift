import Foundation
@testable import WalkMateLib

struct FTMSParserTests: TestSuite {
    static let suiteName = "FTMSParser"

    private static func data(_ bytes: [UInt8]) -> Data { Data(bytes) }

    static func allTests() -> [(String, () -> TestResult)] {
        [
            ("testParseMinimalPacket", testParseMinimalPacket),
            ("testParseWithTotalDistance", testParseWithTotalDistance),
            ("testParseWithElapsedTime", testParseWithElapsedTime),
            ("testParseFullPacket", testParseFullPacket),
            ("testParseEmptyData", testParseEmptyData),
            ("testParseTruncatedData", testParseTruncatedData),
            ("testParseSpeedResolution", testParseSpeedResolution),
            ("testParseDistanceUint24", testParseDistanceUint24),
            ("testParseSingleByte", testParseSingleByte),
            ("testParseSupportedSpeedRange", testParseSupportedSpeedRange),
        ]
    }

    static func testParseMinimalPacket() -> TestResult {
        let packet = data([0x00, 0x00, 0x5E, 0x01])
        guard let r = FTMSParser.parseTreadmillData(packet) else { return .fail("nil result") }
        return runAssertions([
            assertEqualDouble(r.instantaneousSpeed, 3.50),
            assertNil(r.totalDistance),
            assertNil(r.elapsedTime),
            assertNil(r.averageSpeed),
            assertNil(r.totalEnergy),
            assertNil(r.heartRate),
        ])
    }

    static func testParseWithTotalDistance() -> TestResult {
        let packet = data([0x04, 0x00, 0xF4, 0x01, 0xDC, 0x05, 0x00])
        guard let r = FTMSParser.parseTreadmillData(packet) else { return .fail("nil result") }
        return runAssertions([
            assertEqualDouble(r.instantaneousSpeed, 5.00),
            assertEqualDouble(r.totalDistance!, 1500.0),
        ])
    }

    static func testParseWithElapsedTime() -> TestResult {
        let packet = data([0x00, 0x04, 0x5E, 0x01, 0x58, 0x02])
        guard let r = FTMSParser.parseTreadmillData(packet) else { return .fail("nil result") }
        return runAssertions([
            assertEqualDouble(r.instantaneousSpeed, 3.50),
            assertEqual(r.elapsedTime!, 600),
        ])
    }

    static func testParseFullPacket() -> TestResult {
        let packet = data([
            0x86, 0x05, 0x90, 0x01, 0x7C, 0x01,
            0xC4, 0x09, 0x00, 0x96, 0x00, 0x2C, 0x01,
            0x05, 0x78, 0x08, 0x07,
        ])
        guard let r = FTMSParser.parseTreadmillData(packet) else { return .fail("nil result") }
        return runAssertions([
            assertEqualDouble(r.instantaneousSpeed, 4.00),
            assertEqualDouble(r.averageSpeed!, 3.80),
            assertEqualDouble(r.totalDistance!, 2500.0),
            assertEqual(r.totalEnergy!, 150),
            assertEqual(r.energyPerHour!, 300),
            assertEqual(r.energyPerMinute!, 5),
            assertEqual(r.heartRate!, 120),
            assertEqual(r.elapsedTime!, 1800),
        ])
    }

    static func testParseEmptyData() -> TestResult {
        assertNil(FTMSParser.parseTreadmillData(Data()))
    }

    static func testParseTruncatedData() -> TestResult {
        let packet = data([0x04, 0x00, 0x5E, 0x01])
        guard let r = FTMSParser.parseTreadmillData(packet) else { return .fail("nil result") }
        return runAssertions([
            assertEqualDouble(r.instantaneousSpeed, 3.50),
            assertNil(r.totalDistance),
        ])
    }

    static func testParseSpeedResolution() -> TestResult {
        let packet = data([0x00, 0x00, 0x5E, 0x01])
        guard let r = FTMSParser.parseTreadmillData(packet) else { return .fail("nil result") }
        return assertEqualDouble(r.instantaneousSpeed, 3.50, accuracy: 0.0001)
    }

    static func testParseDistanceUint24() -> TestResult {
        let packet = data([0x04, 0x00, 0xC8, 0x00, 0xA0, 0x86, 0x01])
        guard let r = FTMSParser.parseTreadmillData(packet) else { return .fail("nil result") }
        return assertEqualDouble(r.totalDistance!, 100000.0)
    }

    static func testParseSingleByte() -> TestResult {
        assertNil(FTMSParser.parseTreadmillData(data([0xFF])))
    }

    static func testParseSupportedSpeedRange() -> TestResult {
        let packet = data([0x64, 0x00, 0xB0, 0x04, 0x0A, 0x00])
        guard let r = FTMSParser.parseSupportedSpeedRange(packet) else { return .fail("nil result") }
        return runAssertions([
            assertEqualDouble(r.minimum, 1.00),
            assertEqualDouble(r.maximum, 12.00),
            assertEqualDouble(r.increment, 0.10),
        ])
    }
}
