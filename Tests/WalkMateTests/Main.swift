import Foundation

@main
struct TestMain {
    static func main() {
        let suites: [any TestSuite.Type] = [
            FTMSParserTests.self,
            GoalsManagerTests.self,
            AchievementManagerTests.self,
        ]

        var totalTests = 0
        var passedTests = 0
        var failedTests = 0

        for suite in suites {
            print("\n--- \(suite.suiteName) ---")
            for (name, test) in suite.allTests() {
                totalTests += 1
                let result = test()
                if result.passed {
                    passedTests += 1
                    print("  \u{2713} \(name)")
                } else {
                    failedTests += 1
                    print("  \u{2717} \(name): \(result.message)")
                }
            }
        }

        print("\n=== Results: \(passedTests)/\(totalTests) passed, \(failedTests) failed ===")

        if failedTests > 0 {
            exit(1)
        }
    }
}
