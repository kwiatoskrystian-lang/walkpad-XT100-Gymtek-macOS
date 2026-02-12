import Charts
import SwiftUI

struct WeeklyChartSection: View {
    private let store = DataStore.shared
    private let goals = GoalsManager.shared

    @State private var selectedDay: Int?

    private var weekData: [WeekDayData] {
        let calendar = Calendar.current
        let now = Date()

        var weekStart = calendar.startOfDay(for: now)
        while calendar.component(.weekday, from: weekStart) != 2 {
            weekStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
        }

        let todayStart = calendar.startOfDay(for: now)
        let workouts = store.completedWorkouts()
        let dayNames = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"]

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            let dayWorkouts = workouts.filter { $0.startDate >= day && $0.startDate < dayEnd }
            let distance = dayWorkouts.reduce(0.0) { $0 + $1.distance }
            let calories = dayWorkouts.reduce(0) { $0 + ($1.calories ?? 0) }

            let isFuture = day > todayStart
            let goal = store.goalForDate(day)
            let goalAchieved = goal?.isAchieved ?? false

            return WeekDayData(
                dayIndex: offset,
                dayName: dayNames[offset],
                distance: distance,
                calories: calories,
                isFuture: isFuture,
                goalAchieved: goalAchieved
            )
        }
    }

    private var weekTotal: Double {
        weekData.reduce(0.0) { $0 + $1.distance }
    }

    private var weekCalories: Int {
        weekData.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.blue)
                Text("Ten tydzień")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text(String(format: "%.1f km · %d kcal", weekTotal, weekCalories))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Chart
            Chart(weekData) { item in
                BarMark(
                    x: .value("Dzień", item.dayName),
                    y: .value("km", item.displayDistance)
                )
                .foregroundStyle(item.barGradient)
                .cornerRadius(3)

                // Highlight selected bar
                if let sel = selectedDay, sel == item.dayIndex {
                    RuleMark(x: .value("Dzień", item.dayName))
                        .foregroundStyle(.primary.opacity(0.08))
                }
            }
            .frame(height: 90)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 8))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.system(size: 8))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let dayName: String = proxy.value(atX: location.x) else { return }
                            if let idx = weekData.firstIndex(where: { $0.dayName == dayName }) {
                                selectedDay = selectedDay == idx ? nil : idx
                            }
                        }
                }
            }

            // Tooltip
            if let idx = selectedDay, idx < weekData.count {
                let day = weekData[idx]
                HStack(spacing: 4) {
                    Circle()
                        .fill(day.barColor)
                        .frame(width: 5, height: 5)
                    Text("\(day.dayName): \(String(format: "%.2f km", day.distance)) · \(day.calories) kcal")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct WeekDayData: Identifiable {
    let dayIndex: Int
    let dayName: String
    let distance: Double
    let calories: Int
    let isFuture: Bool
    let goalAchieved: Bool

    var id: Int { dayIndex }

    var displayDistance: Double {
        isFuture ? 0 : distance
    }

    var barColor: Color {
        if isFuture { return .gray.opacity(0.3) }
        if goalAchieved { return .green }
        if distance > 0 { return .blue }
        return .gray.opacity(0.3)
    }

    var barGradient: AnyShapeStyle {
        if isFuture { return AnyShapeStyle(.gray.opacity(0.15)) }
        if goalAchieved {
            return AnyShapeStyle(
                .linearGradient(
                    colors: [.green.opacity(0.6), .green],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        if distance > 0 {
            return AnyShapeStyle(
                .linearGradient(
                    colors: [.blue.opacity(0.5), .blue],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        return AnyShapeStyle(.gray.opacity(0.15))
    }
}
