import Foundation

/// Lightweight test runner — no XCTest dependency.
/// Each test function returns (name, passed, message).
protocol TestSuite {
    static var suiteName: String { get }
    static func allTests() -> [(String, () -> TestResult)]
}

struct TestResult {
    let passed: Bool
    let message: String

    static func pass() -> TestResult { TestResult(passed: true, message: "OK") }
    static func fail(_ msg: String) -> TestResult { TestResult(passed: false, message: msg) }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ context: String = "") -> TestResult {
    a == b ? .pass() : .fail("\(context) Expected \(b), got \(a)")
}

func assertEqualDouble(_ a: Double, _ b: Double, accuracy: Double = 0.001, _ context: String = "") -> TestResult {
    abs(a - b) < accuracy ? .pass() : .fail("\(context) Expected \(b) ± \(accuracy), got \(a)")
}

func assertNil<T>(_ value: T?, _ context: String = "") -> TestResult {
    value == nil ? .pass() : .fail("\(context) Expected nil, got \(value!)")
}

func assertNotNil<T>(_ value: T?, _ context: String = "") -> TestResult {
    value != nil ? .pass() : .fail("\(context) Expected non-nil, got nil")
}

func assertTrue(_ value: Bool, _ context: String = "") -> TestResult {
    value ? .pass() : .fail("\(context) Expected true, got false")
}

func assertFalse(_ value: Bool, _ context: String = "") -> TestResult {
    !value ? .pass() : .fail("\(context) Expected false, got true")
}

/// Run multiple assertions — returns first failure or pass
func runAssertions(_ checks: [TestResult]) -> TestResult {
    for check in checks {
        if !check.passed { return check }
    }
    return .pass()
}
