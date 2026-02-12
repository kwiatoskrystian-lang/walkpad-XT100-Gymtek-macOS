import Charts
import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()

    private var summaryStats: (count: Int, totalKm: Double, totalCal: Int, avgSpeed: Double) {
        let w = viewModel.workouts
        let km = w.reduce(0.0) { $0 + $1.distance }
        let cal = w.reduce(0) { $0 + ($1.calories ?? 0) }
        let speeds = w.filter { $0.averageSpeed > 0 }.map(\.averageSpeed)
        let avg = speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
        return (w.count, km, cal, avg)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13))
                            .foregroundStyle(.blue)
                        Text("Historia treningów")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Spacer()
                    Text("\(viewModel.workouts.count) treningów")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)

                if viewModel.workouts.isEmpty {
                    emptyState
                } else {
                    // Summary strip
                    let stats = summaryStats
                    HStack(spacing: 0) {
                        HistorySummaryStat(
                            icon: "figure.walk",
                            value: String(format: "%.1f km", stats.totalKm),
                            color: .blue
                        )
                        Divider().frame(height: 24)
                        HistorySummaryStat(
                            icon: "flame.fill",
                            value: "\(stats.totalCal) kcal",
                            color: .orange
                        )
                        Divider().frame(height: 24)
                        HistorySummaryStat(
                            icon: "speedometer",
                            value: String(format: "%.1f km/h", stats.avgSpeed),
                            color: .cyan
                        )
                    }
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 12)

                    // Workout list
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.workouts) { workout in
                            WorkoutRow(
                                workout: workout,
                                viewModel: viewModel,
                                isExpanded: viewModel.expandedWorkoutID == workout.id
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "figure.walk")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue.opacity(0.5))
            }
            Text("Brak treningów")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Włącz bieżnię, aby rozpocząć\npierwszy trening.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Summary Stat

private struct HistorySummaryStat: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Workout Row

struct WorkoutRow: View {
    let workout: Workout
    let viewModel: HistoryViewModel
    let isExpanded: Bool

    private var distanceColor: Color {
        if workout.distance >= 5 { return .green }
        if workout.distance >= 2 { return .blue }
        return .orange
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.toggleExpanded(workout.id)
                }
            } label: {
                HStack(spacing: 10) {
                    // Distance badge
                    VStack(spacing: 1) {
                        Text(String(format: "%.1f", workout.distance))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("km")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 38)
                    .padding(.vertical, 4)
                    .background(distanceColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.formattedDate(workout.startDate))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.blue)
                                Text(viewModel.formattedDuration(workout.duration))
                                    .font(.system(size: 10, weight: .medium))
                            }

                            HStack(spacing: 3) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.cyan)
                                Text(String(format: "%.1f km/h", workout.averageSpeed))
                                    .font(.system(size: 10, weight: .medium))
                            }

                            if let cal = workout.calories, cal > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.orange)
                                    Text("\(cal) kcal")
                                        .font(.system(size: 10, weight: .medium))
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                WorkoutDetailSection(workout: workout, viewModel: viewModel)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
    }
}

// MARK: - Workout Detail Section

private struct WorkoutDetailSection: View {
    let workout: Workout
    let viewModel: HistoryViewModel

    private var splits: [KmSplit] {
        let samples = workout.speedSamples
        guard !samples.isEmpty else { return [] }

        let totalKm = workout.distance
        let fullKms = Int(totalKm)
        var result: [KmSplit] = []

        for km in 0..<fullKms {
            let kmStart = Double(km)
            let kmEnd = Double(km + 1)
            let relevantSamples = samples.filter { s in
                let estimatedKm = estimateDistance(at: s.timestamp, samples: samples)
                return estimatedKm >= kmStart && estimatedKm < kmEnd
            }
            let avgSpeed = relevantSamples.isEmpty
                ? workout.averageSpeed
                : relevantSamples.map(\.speed).reduce(0, +) / Double(relevantSamples.count)
            let pace = avgSpeed > 0 ? 60.0 / avgSpeed : 0
            result.append(KmSplit(km: km + 1, avgSpeed: avgSpeed, pace: pace))
        }

        let remainder = totalKm - Double(fullKms)
        if remainder > 0.05 {
            let kmStart = Double(fullKms)
            let relevantSamples = samples.filter { s in
                estimateDistance(at: s.timestamp, samples: samples) >= kmStart
            }
            let avgSpeed = relevantSamples.isEmpty
                ? workout.averageSpeed
                : relevantSamples.map(\.speed).reduce(0, +) / Double(relevantSamples.count)
            let pace = avgSpeed > 0 ? 60.0 / avgSpeed : 0
            result.append(KmSplit(km: fullKms + 1, avgSpeed: avgSpeed, pace: pace, partial: remainder))
        }

        return result
    }

    var body: some View {
        VStack(spacing: 8) {
            // Colored divider
            Rectangle()
                .fill(
                    .linearGradient(
                        colors: [.blue.opacity(0.3), .cyan.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Stats grid
            HStack(spacing: 8) {
                DetailItem(
                    icon: "gauge.with.dots.needle.33percent",
                    label: "Maks.",
                    value: String(format: "%.1f km/h", workout.maxSpeed),
                    color: .red
                )
                DetailItem(
                    icon: "speedometer",
                    label: "Średnia",
                    value: String(format: "%.1f km/h", workout.averageSpeed),
                    color: .blue
                )
                if let cal = workout.calories {
                    DetailItem(
                        icon: "flame.fill",
                        label: "Kalorie",
                        value: "\(cal) kcal",
                        color: .orange
                    )
                }
            }

            // Speed chart
            if !workout.speedSamples.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prędkość")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Chart(workout.speedSamples) { sample in
                        AreaMark(
                            x: .value("Czas", sample.timestamp / 60),
                            y: .value("km/h", sample.speed)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue.opacity(0.25), .blue.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Czas", sample.timestamp / 60),
                            y: .value("km/h", sample.speed)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let mins = value.as(Double.self) {
                                    Text("\(Int(mins))m")
                                        .font(.system(size: 7))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let speed = value.as(Double.self) {
                                    Text(String(format: "%.0f", speed))
                                        .font(.system(size: 7))
                                }
                            }
                        }
                    }
                    .frame(height: 70)
                }
            }

            // Km splits
            let kmSplits = splits
            if !kmSplits.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Splity")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ForEach(kmSplits) { split in
                        HStack(spacing: 4) {
                            Text(split.partial != nil
                                ? String(format: "%.2f km", split.partial!)
                                : "\(split.km) km")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .frame(width: 44, alignment: .leading)

                            let maxSpeed = kmSplits.map(\.avgSpeed).max() ?? 1
                            let fraction = maxSpeed > 0 ? split.avgSpeed / maxSpeed : 0

                            GeometryReader { geo in
                                Capsule()
                                    .fill(
                                        .linearGradient(
                                            colors: [splitColor(speed: split.avgSpeed).opacity(0.7), splitColor(speed: split.avgSpeed)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(geo.size.width * fraction, 4), height: 5)
                            }
                            .frame(height: 5)

                            Text(String(format: "%.1f km/h", split.avgSpeed))
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 50, alignment: .trailing)

                            Text(String(format: "%.1f'/km", split.pace))
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private func splitColor(speed: Double) -> Color {
        if speed >= 5.5 { return .green }
        if speed >= 4.0 { return .blue }
        return .orange
    }

    private func estimateDistance(at timestamp: TimeInterval, samples: [SpeedSample]) -> Double {
        var distance = 0.0
        let sorted = samples.sorted { $0.timestamp < $1.timestamp }
        for i in 0..<sorted.count {
            guard sorted[i].timestamp <= timestamp else { break }
            let dt: Double
            if i + 1 < sorted.count {
                dt = min(sorted[i + 1].timestamp, timestamp) - sorted[i].timestamp
            } else {
                dt = 0
            }
            distance += (sorted[i].speed / 3600.0) * dt
        }
        return distance
    }
}

// MARK: - Detail Item

private struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 7))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct KmSplit: Identifiable {
    let km: Int
    let avgSpeed: Double
    let pace: Double
    var partial: Double? = nil

    var id: Int { km }
}
