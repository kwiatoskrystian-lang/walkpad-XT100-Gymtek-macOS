import SwiftUI

struct InsightsSection: View {
    private let store = DataStore.shared

    private var insights: [Insight] {
        var result: [Insight] = []
        let calendar = Calendar.current
        let now = Date()
        let workouts = store.completedWorkouts()

        // Weekly comparison
        let thisWeekStart = weekStart(for: now, calendar: calendar)
        let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!

        let thisWeekKm = workouts
            .filter { $0.startDate >= thisWeekStart }
            .reduce(0.0) { $0 + $1.distance }
        let lastWeekKm = workouts
            .filter { $0.startDate >= lastWeekStart && $0.startDate < thisWeekStart }
            .reduce(0.0) { $0 + $1.distance }

        let thisWeekCal = workouts
            .filter { $0.startDate >= thisWeekStart }
            .reduce(0) { $0 + ($1.calories ?? 0) }
        let lastWeekCal = workouts
            .filter { $0.startDate >= lastWeekStart && $0.startDate < thisWeekStart }
            .reduce(0) { $0 + ($1.calories ?? 0) }

        if lastWeekKm > 0 {
            let pct = ((thisWeekKm - lastWeekKm) / lastWeekKm) * 100
            if abs(pct) >= 5 {
                let direction = pct > 0 ? "więcej" : "mniej"
                let icon = pct > 0 ? "arrow.up.right" : "arrow.down.right"
                let color: InsightColor = pct > 0 ? .green : .orange
                let calDetail = thisWeekCal > 0 || lastWeekCal > 0
                    ? " · \(thisWeekCal) vs \(lastWeekCal) kcal"
                    : ""
                result.append(Insight(
                    icon: icon,
                    text: String(format: "%.0f%% %@ niż zeszły tydzień", abs(pct), direction),
                    detail: String(format: "%.1f km vs %.1f km", thisWeekKm, lastWeekKm) + calDetail,
                    color: color
                ))
            }
        }

        // Monthly comparison
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!

        let thisMonthKm = workouts
            .filter { $0.startDate >= thisMonthStart }
            .reduce(0.0) { $0 + $1.distance }
        let lastMonthKm = workouts
            .filter { $0.startDate >= lastMonthStart && $0.startDate < thisMonthStart }
            .reduce(0.0) { $0 + $1.distance }

        let thisMonthCal = workouts
            .filter { $0.startDate >= thisMonthStart }
            .reduce(0) { $0 + ($1.calories ?? 0) }
        let lastMonthCal = workouts
            .filter { $0.startDate >= lastMonthStart && $0.startDate < thisMonthStart }
            .reduce(0) { $0 + ($1.calories ?? 0) }

        if lastMonthKm > 0 {
            let pct = ((thisMonthKm - lastMonthKm) / lastMonthKm) * 100
            if abs(pct) >= 5 {
                let direction = pct > 0 ? "więcej" : "mniej"
                let icon = pct > 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis"
                let color: InsightColor = pct > 0 ? .green : .orange
                let calDetail = thisMonthCal > 0 || lastMonthCal > 0
                    ? " · \(thisMonthCal) vs \(lastMonthCal) kcal"
                    : ""
                result.append(Insight(
                    icon: icon,
                    text: String(format: "%.0f%% %@ niż zeszły miesiąc", abs(pct), direction),
                    detail: String(format: "%.1f km vs %.1f km", thisMonthKm, lastMonthKm) + calDetail,
                    color: color
                ))
            }
        }

        // Best week ever check
        let allWeekTotals = weeklyTotals(workouts: workouts, calendar: calendar)
        let bestWeekKm = allWeekTotals.max() ?? 0
        if thisWeekKm > 0 && thisWeekKm >= bestWeekKm && allWeekTotals.count > 1 {
            result.append(Insight(
                icon: "trophy.fill",
                text: "Najlepszy tydzień w historii!",
                detail: String(format: "%.1f km", thisWeekKm),
                color: .gold
            ))
        }

        // Avg speed trend
        let recentWorkouts = workouts.sorted(by: { $0.startDate > $1.startDate })
        if recentWorkouts.count >= 4 {
            let recent3Avg = recentWorkouts.prefix(3).map(\.averageSpeed).reduce(0, +) / 3
            let prev3Avg = recentWorkouts.dropFirst(3).prefix(3).map(\.averageSpeed).reduce(0, +)
                / Double(min(recentWorkouts.dropFirst(3).prefix(3).count, 3))
            if prev3Avg > 0 {
                let pct = ((recent3Avg - prev3Avg) / prev3Avg) * 100
                if pct >= 5 {
                    result.append(Insight(
                        icon: "bolt.fill",
                        text: String(format: "Prędkość rośnie! +%.0f%%", pct),
                        detail: String(format: "Średnio %.1f km/h", recent3Avg),
                        color: .blue
                    ))
                }
            }
        }

        // Week forecast
        let todayWeekday = calendar.component(.weekday, from: now)
        // Convert to Mon=1..Sun=7
        let daysSoFar = todayWeekday == 1 ? 7 : todayWeekday - 1
        if daysSoFar >= 2 && thisWeekKm > 0 {
            let avgPerDay = thisWeekKm / Double(daysSoFar)
            let daysLeft = 7 - daysSoFar
            let forecast = thisWeekKm + avgPerDay * Double(daysLeft)
            result.append(Insight(
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                text: String(format: "Prognoza: %.1f km do końca tygodnia", forecast),
                detail: String(format: "Średnio %.1f km/dzień", avgPerDay),
                color: .blue
            ))
        }

        return result
    }

    var body: some View {
        let items = insights
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                    Text("Wgląd")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                }

                ForEach(Array(items.enumerated()), id: \.element.id) { idx, insight in
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(insight.color.swiftUIColor.opacity(0.12))
                                .frame(width: 22, height: 22)

                            Image(systemName: insight.icon)
                                .font(.system(size: 9))
                                .foregroundStyle(insight.color.swiftUIColor)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(insight.text)
                                .font(.system(size: 10, weight: .medium))
                            Text(insight.detail)
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Helpers

    private func weekStart(for date: Date, calendar: Calendar) -> Date {
        var d = calendar.startOfDay(for: date)
        while calendar.component(.weekday, from: d) != 2 {
            d = calendar.date(byAdding: .day, value: -1, to: d)!
        }
        return d
    }

    private func weeklyTotals(workouts: [Workout], calendar: Calendar) -> [Double] {
        guard let earliest = workouts.map(\.startDate).min() else { return [] }
        var ws = weekStart(for: earliest, calendar: calendar)
        let now = Date()
        var totals: [Double] = []

        while ws <= now {
            let we = calendar.date(byAdding: .day, value: 7, to: ws)!
            let km = workouts
                .filter { $0.startDate >= ws && $0.startDate < we }
                .reduce(0.0) { $0 + $1.distance }
            totals.append(km)
            ws = we
        }
        return totals
    }
}

private enum InsightColor: Equatable {
    case green, orange, gold, blue

    var swiftUIColor: Color {
        switch self {
        case .green: .green
        case .orange: .orange
        case .gold: .yellow
        case .blue: .blue
        }
    }
}

private struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let detail: String
    let color: InsightColor
}
