import Foundation
@testable import WalkMateLib

struct AchievementManagerTests: TestSuite {
    static let suiteName = "AchievementManager"

    static func allTests() -> [(String, () -> TestResult)] {
        [
            ("testFirstWorkoutAchievement", testFirstWorkoutAchievement),
            ("testDistanceAchievementThreshold", testDistanceAchievementThreshold),
            ("testAchievementNotDuplicated", testAchievementNotDuplicated),
            ("testAchievementUnlockSetsDate", testAchievementUnlockSetsDate),
            ("testAllAchievementsDefined", testAllAchievementsDefined),
            ("testSpeedAchievements", testSpeedAchievements),
        ]
    }

    static func testFirstWorkoutAchievement() -> TestResult {
        guard let fw = AchievementDefinitions.all.first(where: { $0.id == "first_workout" }) else {
            return .fail("first_workout not found")
        }
        return runAssertions([
            assertEqual(fw.name, "Pierwszy krok"),
            assertEqual(fw.category, "distance"),
            assertEqualDouble(fw.threshold, 0.0),
        ])
    }

    static func testDistanceAchievementThreshold() -> TestResult {
        guard let m = AchievementDefinitions.all.first(where: { $0.id == "marathon" }) else {
            return .fail("marathon not found")
        }
        return runAssertions([
            assertEqualDouble(m.threshold, 42.195),
            assertEqual(m.name, "Maratończyk"),
        ])
    }

    static func testAchievementNotDuplicated() -> TestResult {
        let ids = AchievementDefinitions.all.map(\.id)
        let unique = Set(ids)
        return assertEqual(ids.count, unique.count, "IDs not unique")
    }

    static func testAchievementUnlockSetsDate() -> TestResult {
        var a = Achievement(
            achievementID: "test", name: "Test", description: "Test",
            iconName: "star", threshold: 5.0, category: "distance"
        )
        let check1 = assertFalse(a.isUnlocked)
        if !check1.passed { return check1 }

        a.unlockedDate = Date()
        return assertTrue(a.isUnlocked)
    }

    static func testAllAchievementsDefined() -> TestResult {
        assertEqual(AchievementDefinitions.all.count, 28)
    }

    static func testSpeedAchievements() -> TestResult {
        let speed = AchievementDefinitions.all.filter { $0.category == "speed" }
        let check = assertEqual(speed.count, 2)
        if !check.passed { return check }

        guard let s5 = speed.first(where: { $0.id == "speed_5" }),
              let s6 = speed.first(where: { $0.id == "speed_6" }) else {
            return .fail("Speed achievements not found")
        }
        return runAssertions([
            assertEqualDouble(s5.threshold, 5.0),
            assertEqualDouble(s6.threshold, 6.0),
        ])
    }
}
