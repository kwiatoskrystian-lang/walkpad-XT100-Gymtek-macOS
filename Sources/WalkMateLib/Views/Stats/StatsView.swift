import Charts
import SwiftUI

struct StatsView: View {
    @State private var vm = StatsViewModel()
    private let store = DataStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // MARK: - Hero Section
                heroSection

                // MARK: - Quick Stats Row
                quickStatsRow

                // MARK: - Activity Heatmap
                activityHeatmap

                // MARK: - Monthly Chart
                monthlyChart

                // MARK: - Speed Trend
                if vm.speedTrend.count >= 3 {
                    speedTrendChart
                }

                // MARK: - Records
                recordsSection

                // MARK: - Fun Stats
                funStatsSection

                // MARK: - Weight & BMI Chart
                WeightChartSection(
                    entries: store.sortedWeightEntries(),
                    heightCm: AppSettings.shared.userHeight
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear {
            vm.refresh()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text(currentMonthName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if let pct = vm.monthVsLastMonthPct {
                    HStack(spacing: 2) {
                        Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(String(format: "%.0f%%", abs(pct)))
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(pct >= 0 ? .green : .orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((pct >= 0 ? Color.green : .orange).opacity(0.15), in: Capsule())
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", vm.monthlyTotalDistance))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("km")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Sub-stats
            HStack(spacing: 16) {
                HeroStat(icon: "clock.fill", value: vm.formattedTotalTime, color: .blue)
                HeroStat(icon: "flame.fill", value: "\(vm.monthlyTotalCalories) kcal", color: .orange)
                HeroStat(icon: "shoeprints.fill", value: formattedSteps(vm.monthlyTotalSteps), color: .green)
                HeroStat(icon: "number", value: "\(vm.monthlyWorkoutCount) tr.", color: .purple)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.08), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 8) {
            MiniStatCard(
                icon: "speedometer",
                label: "Śr. prędk.",
                value: String(format: "%.1f km/h", vm.monthlyAvgSpeed),
                gradient: [.cyan, .blue]
            )
            MiniStatCard(
                icon: "timer",
                label: "Śr. trening",
                value: vm.formattedAvgWorkoutDuration,
                gradient: [.purple, .indigo]
            )
            MiniStatCard(
                icon: "target",
                label: "Cele",
                value: String(format: "%.0f%%", vm.monthlyGoalCompletionRate * 100),
                gradient: [.green, .mint]
            )
            MiniStatCard(
                icon: "calendar",
                label: "Aktywne dni",
                value: "\(vm.monthlyActiveDays)",
                gradient: [.orange, .yellow]
            )
        }
    }

    // MARK: - Activity Heatmap

    private var activityHeatmap: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Aktywność — ostatnie 5 tygodni")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(.gray.opacity(0.2)).frame(width: 6, height: 6)
                    Text("brak")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text("cel")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
            let dayLabels = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"]

            // Day labels
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(vm.activityHeatmap) { day in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(for: day))
                        .frame(height: 14)
                        .overlay {
                            if day.goalAchieved {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 5, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Monthly Chart

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Dystans dzienny")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text(String(format: "śr. %.1f km/d", vm.monthlyAvgPerDay))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            let goalLine = AppSettings.shared.dailyGoalDistance

            Chart {
                ForEach(vm.dailyDistances, id: \.day) { item in
                    BarMark(
                        x: .value("Dzień", item.day),
                        y: .value("km", item.distance)
                    )
                    .foregroundStyle(
                        item.distance >= goalLine
                            ? Color.green.gradient
                            : Color.blue.gradient
                    )
                    .cornerRadius(2)
                }

                RuleMark(y: .value("Cel", goalLine))
                    .foregroundStyle(.orange.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(position: .trailing, alignment: .trailing) {
                        Text("cel")
                            .font(.system(size: 7))
                            .foregroundStyle(.orange)
                    }
            }
            .frame(height: 100)
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { _ in
                    AxisValueLabel()
                        .font(.system(size: 8))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .font(.system(size: 8))
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }

            // Best day callout
            if let bestDay = vm.dailyDistances.max(by: { $0.distance < $1.distance }),
               bestDay.distance > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                    Text("Najlepszy dzień: \(bestDay.day). — \(String(format: "%.2f km", bestDay.distance))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Speed Trend

    private var speedTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Trend prędkości")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                if let last = vm.speedTrend.last, let first = vm.speedTrend.first {
                    let diff = last.speed - first.speed
                    if abs(diff) > 0.1 {
                        HStack(spacing: 2) {
                            Image(systemName: diff > 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 8, weight: .bold))
                            Text(String(format: "%+.1f km/h", diff))
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundStyle(diff > 0 ? .green : .orange)
                    }
                }
            }

            Chart(vm.speedTrend, id: \.index) { item in
                LineMark(
                    x: .value("Nr", item.index + 1),
                    y: .value("km/h", item.speed)
                )
                .foregroundStyle(.cyan)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Nr", item.index + 1),
                    y: .value("km/h", item.speed)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.cyan.opacity(0.3), .cyan.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Nr", item.index + 1),
                    y: .value("km/h", item.speed)
                )
                .foregroundStyle(.cyan)
                .symbolSize(15)
            }
            .frame(height: 70)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 7))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .font(.system(size: 8))
                }
            }

            Text("Ostatnie \(vm.speedTrend.count) treningów")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Records

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
                Text("Rekordy wszech czasów")
                    .font(.system(size: 13, weight: .bold))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                RecordCard(
                    icon: "road.lanes",
                    value: String(format: "%.2f km", vm.longestWorkoutDistance),
                    label: "Najdłuższy spacer",
                    gradient: [.orange, .yellow]
                )
                RecordCard(
                    icon: "timer",
                    value: vm.formattedLongestDuration,
                    label: "Najdłuższy czas",
                    gradient: [.purple, .pink]
                )
                RecordCard(
                    icon: "hare.fill",
                    value: String(format: "%.1f km/h", vm.fastestAvgSpeed),
                    label: "Najszybsze śr.",
                    gradient: [.cyan, .blue]
                )
                RecordCard(
                    icon: "flame.fill",
                    value: "\(vm.longestStreak) dni",
                    label: "Najdłuższa passa",
                    gradient: [.red, .orange]
                )
            }

            // Lifetime stats strip
            HStack(spacing: 0) {
                LifetimeStat(value: String(format: "%.1f km", vm.totalLifetimeKm), label: "Łącznie", icon: "map.fill")
                Divider().frame(height: 30)
                LifetimeStat(value: vm.formattedLifetimeHours, label: "Godzin", icon: "clock.fill")
                Divider().frame(height: 30)
                LifetimeStat(value: formattedSteps(vm.totalLifetimeSteps), label: "Kroków", icon: "shoeprints.fill")
                Divider().frame(height: 30)
                LifetimeStat(value: "\(vm.totalLifetimeWorkouts)", label: "Treningów", icon: "figure.walk")
            }
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.06), .orange.opacity(0.04), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Fun Stats

    private var funStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(.purple)
                Text("Ciekawostki")
                    .font(.system(size: 13, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 6) {
                if vm.totalLifetimeKm > 0 {
                    FunFactRow(
                        emoji: distanceEmoji,
                        text: distanceFunFact
                    )
                }

                if let day = vm.favoriteDayOfWeek {
                    FunFactRow(
                        emoji: "📅",
                        text: "Najczęściej trenujesz w: \(day)"
                    )
                }

                if let time = vm.favoriteTimeOfDay {
                    FunFactRow(
                        emoji: timeEmoji(time),
                        text: "Ulubiona pora: \(time)"
                    )
                }

                if vm.bestWeekEverKm > 0 {
                    FunFactRow(
                        emoji: "🏆",
                        text: String(format: "Najlepszy tydzień: %.1f km", vm.bestWeekEverKm)
                    )
                }

                if vm.avgWorkoutsPerWeek > 0 {
                    FunFactRow(
                        emoji: "📊",
                        text: String(format: "Śr. %.1f treningów/tydzień", vm.avgWorkoutsPerWeek)
                    )
                }

                if vm.currentStreak > 0 {
                    FunFactRow(
                        emoji: "🔥",
                        text: "\(vm.currentStreak) dni z rzędu — tak trzymaj!"
                    )
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func formattedSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }

    private var currentMonthName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: Date()).capitalized
    }

    private func heatmapColor(for day: StatsViewModel.HeatmapDay) -> Color {
        if day.goalAchieved { return .green }
        if day.distance > 0 {
            let intensity = min(day.distance / max(AppSettings.shared.dailyGoalDistance, 1), 1.0)
            return .blue.opacity(0.2 + intensity * 0.6)
        }
        return .gray.opacity(0.12)
    }

    private var distanceEmoji: String {
        let km = vm.totalLifetimeKm
        if km >= 100 { return "🌍" }
        if km >= 50 { return "🚀" }
        if km >= 20 { return "🏃" }
        return "👟"
    }

    private var distanceFunFact: String {
        let km = vm.totalLifetimeKm
        if km >= 400 { return String(format: "Przeszedłeś %.0f km — to jak z Warszawy do Berlina!", km) }
        if km >= 300 { return String(format: "Przeszedłeś %.0f km — to jak z Warszawy do Krakowa!", km) }
        if km >= 130 { return String(format: "Przeszedłeś %.0f km — to jak z Warszawy do Łodzi!", km) }
        if km >= 42 { return String(format: "Przeszedłeś %.0f km — to więcej niż maraton!", km) }
        if km >= 21 { return String(format: "Przeszedłeś %.0f km — półmaraton za Tobą!", km) }
        if km >= 10 { return String(format: "Przeszedłeś %.0f km — świetny początek!", km) }
        return String(format: "Przeszedłeś %.1f km — każdy krok się liczy!", km)
    }

    private func timeEmoji(_ time: String) -> String {
        switch time {
        case "Rano": return "🌅"
        case "Popołudnie": return "☀️"
        default: return "🌙"
        }
    }
}

// MARK: - Sub-components

private struct HeroStat: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

private struct MiniStatCard: View {
    let icon: String
    let label: String
    let value: String
    let gradient: [Color]

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(
                    .linearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct RecordCard: View {
    let icon: String
    let value: String
    let label: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        .linearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LifetimeStat: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 7))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FunFactRow: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Weight Chart (unchanged)

struct WeightChartSection: View {
    let entries: [WeightEntry]
    var heightCm: Double = 184

    private var heightM: Double { heightCm / 100 }

    private func bmi(for weight: Double) -> Double {
        guard heightM > 0 else { return 0 }
        return weight / (heightM * heightM)
    }

    private func bmiCategory(_ bmi: Double) -> (text: String, color: Color) {
        switch bmi {
        case ..<18.5: return ("Niedowaga", .orange)
        case 18.5..<25: return ("Norma", .green)
        case 25..<30: return ("Nadwaga", .orange)
        default: return ("Otyłość", .red)
        }
    }

    var body: some View {
        if entries.count >= 2 {
            VStack(alignment: .leading, spacing: 8) {
                // Header with weight diff
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.purple)
                        Text("Waga & BMI")
                            .font(.system(size: 11, weight: .semibold))
                    }

                    Spacer()

                    if let first = entries.first, let last = entries.last {
                        let diff = last.weight - first.weight
                        let sign = diff >= 0 ? "+" : ""
                        Text(String(format: "%@%.1f kg", sign, diff))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(diff <= 0 ? .green : .orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((diff <= 0 ? Color.green : .orange).opacity(0.12), in: Capsule())
                    }
                }

                // BMI indicator
                if let latest = entries.last {
                    let currentBMI = bmi(for: latest.weight)
                    let category = bmiCategory(currentBMI)

                    HStack(spacing: 12) {
                        // BMI value
                        VStack(spacing: 1) {
                            Text("BMI")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f", currentBMI))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }

                        // BMI bar
                        VStack(alignment: .leading, spacing: 3) {
                            // Category label
                            Text(category.text)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(category.color)

                            // Visual BMI scale bar
                            GeometryReader { geo in
                                let w = geo.size.width
                                ZStack(alignment: .leading) {
                                    // Background gradient bar
                                    HStack(spacing: 0) {
                                        Color.orange.opacity(0.5)
                                            .frame(width: w * 0.23)
                                        Color.green.opacity(0.5)
                                            .frame(width: w * 0.32)
                                        Color.orange.opacity(0.5)
                                            .frame(width: w * 0.25)
                                        Color.red.opacity(0.5)
                                            .frame(width: w * 0.20)
                                    }
                                    .clipShape(Capsule())

                                    // Indicator triangle
                                    let clampedBMI = min(max(currentBMI, 15), 40)
                                    let position = (clampedBMI - 15) / 25 * w
                                    Image(systemName: "arrowtriangle.up.fill")
                                        .font(.system(size: 7))
                                        .foregroundStyle(category.color)
                                        .offset(x: position - 4, y: 6)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding(8)
                    .background(category.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }

                // Weight chart
                Chart(entries) { entry in
                    LineMark(
                        x: .value("Data", entry.date),
                        y: .value("kg", entry.weight)
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Data", entry.date),
                        y: .value("kg", entry.weight)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.purple.opacity(0.3), .purple.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Data", entry.date),
                        y: .value("kg", entry.weight)
                    )
                    .foregroundStyle(.purple)
                    .symbolSize(16)
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(.system(size: 7))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .font(.system(size: 8))
                    }
                }

                if let latest = entries.last {
                    Text(String(format: "Aktualna: %.1f kg • BMI: %.1f", latest.weight, bmi(for: latest.weight)))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Shared StatCard (used in other views)

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
                .contentTransition(.numericText())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
