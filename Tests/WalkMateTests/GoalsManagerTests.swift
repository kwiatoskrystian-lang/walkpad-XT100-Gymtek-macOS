import Foundation
@testable import WalkMateLib

struct GoalsManagerTests: TestSuite {
    static let suiteName = "GoalsManager"

    static func allTests() -> [(String, () -> TestResult)] {
        [
            ("testDailyGoalCreation", testDailyGoalCreation),
            ("testDailyGoalProgress", testDailyGoalProgress),
            ("testDailyGoalAchieved", testDailyGoalAchieved),
            ("testDailyGoalNotAchieved", testDailyGoalNotAchieved),
            ("testCustomTargetDistance", testCustomTargetDistance),
        ]
    }

    static func testDailyGoalCreation() -> TestResult {
        let goal = DailyGoal()
        return runAssertions([
            assertEqualDouble(goal.targetDistance, 10.0),
            assertEqualDouble(goal.completedDistance, 0.0),
            assertFalse(goal.isAchieved),
            assertTrue(Calendar.current.isDateInToday(goal.date)),
        ])
    }

    static func testDailyGoalProgress() -> TestResult {
        var goal = DailyGoal(targetDistance: 10.0)
        goal.completedDistance = 5.0
        let check1 = assertEqualDouble(goal.completedDistance, 5.0)
        if !check1.passed { return check1 }

        goal.completedDistance = 7.5
        return assertEqualDouble(goal.completedDistance, 7.5)
    }

    static func testDailyGoalAchieved() -> TestResult {
        var goal = DailyGoal(targetDistance: 10.0)
        goal.completedDistance = 10.5
        goal.isAchieved = goal.completedDistance >= goal.targetDistance
        return assertTrue(goal.isAchieved)
    }

    static func testDailyGoalNotAchieved() -> TestResult {
        var goal = DailyGoal(targetDistance: 10.0)
        goal.completedDistance = 9.9
        goal.isAchieved = goal.completedDistance >= goal.targetDistance
        return assertFalse(goal.isAchieved)
    }

    static func testCustomTargetDistance() -> TestResult {
        let goal = DailyGoal(targetDistance: 5.0)
        return assertEqualDouble(goal.targetDistance, 5.0)
    }
}
