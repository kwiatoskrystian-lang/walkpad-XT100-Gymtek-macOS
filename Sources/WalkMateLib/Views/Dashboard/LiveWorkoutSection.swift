import SwiftUI

struct LiveWorkoutSection: View {
    let viewModel: DashboardViewModel

    private var etaTargets: [(label: String, eta: String)] {
        let speed = viewModel.currentSpeed
        let dist = viewModel.currentDistance
        guard speed > 0.3 else { return [] }

        var targets: [(String, String)] = []
        for km in [5.0, 10.0] {
            let remaining = km - dist
            if remaining > 0 {
                let hours = remaining / speed
                let totalMinutes = Int(hours * 60)
                let h = totalMinutes / 60
                let m = totalMinutes % 60
                let etaStr = h > 0 ? "\(h)h \(m)m" : "\(m)m"
                targets.append(("\(Int(km)) km", etaStr))
            }
        }
        return targets
    }

    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack(spacing: 5) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Image(systemName: "figure.walk")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("Trening na żywo")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text(viewModel.formattedDuration)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.green)
            }

            // Speed hero
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(viewModel.formattedSpeed)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("km/h")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Stats row
            HStack(spacing: 0) {
                LiveStatItem(
                    icon: "figure.walk",
                    value: viewModel.formattedDistance,
                    unit: "km",
                    color: .blue
                )
                Divider().frame(height: 28)
                LiveStatItem(
                    icon: "clock",
                    value: viewModel.formattedDuration,
                    unit: "czas",
                    color: .cyan
                )
                Divider().frame(height: 28)
                LiveStatItem(
                    icon: "shoeprints.fill",
                    value: "\(viewModel.estimatedSteps)",
                    unit: "kroki",
                    color: .green
                )
                if let cal = viewModel.calories {
                    Divider().frame(height: 28)
                    LiveStatItem(
                        icon: "flame.fill",
                        value: "\(cal)",
                        unit: "kcal",
                        color: .orange
                    )
                }
                if let hr = viewModel.heartRate, hr > 0 {
                    Divider().frame(height: 28)
                    LiveStatItem(
                        icon: "heart.fill",
                        value: "\(hr)",
                        unit: "bpm",
                        color: .red
                    )
                }
            }
            .padding(.vertical, 6)
            .background(.green.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))

            // ETA targets
            let targets = etaTargets
            if !targets.isEmpty {
                HStack(spacing: 12) {
                    ForEach(targets, id: \.label) { target in
                        HStack(spacing: 3) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.orange)
                            Text(target.label)
                                .font(.system(size: 9, weight: .medium))
                            Text("za ~\(target.eta)")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }

            // Daily goal progress ring
            let uncappedProgress = viewModel.targetDistance > 0
                ? viewModel.todayDistance / viewModel.targetDistance
                : 0

            HStack(spacing: 12) {
                ProgressRing(
                    progress: uncappedProgress,
                    lineWidth: 5,
                    size: 44,
                    showLabel: true
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f / %.1f km", viewModel.todayDistance, viewModel.targetDistance))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                    Text("cel dzienny")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Treadmill control panel
            if viewModel.canControlTreadmill {
                VStack(spacing: 6) {
                    Divider()

                    // Speed +/- and presets — centered
                    HStack(spacing: 10) {
                        Button {
                            viewModel.decreaseSpeed()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 0) {
                            Text(String(format: "%.1f", viewModel.targetSpeed))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Text("cel")
                                .font(.system(size: 7))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(width: 40)

                        Button {
                            viewModel.increaseSpeed()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)

                        Divider().frame(height: 20)

                        // Quick presets
                        HStack(spacing: 3) {
                            ForEach([3.0, 4.0, 5.0, 6.0], id: \.self) { speed in
                                Button {
                                    viewModel.setTargetSpeed(speed)
                                } label: {
                                    Text(String(format: "%.0f", speed))
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .frame(width: 22, height: 18)
                                        .background(
                                            abs(viewModel.targetSpeed - speed) < 0.1
                                                ? Color.green.opacity(0.2)
                                                : Color.primary.opacity(0.06),
                                            in: RoundedRectangle(cornerRadius: 4)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider().frame(height: 20)

                        // Stop button
                        Button {
                            if viewModel.currentSpeed > 0 {
                                viewModel.stopTreadmill()
                            } else {
                                viewModel.startTreadmill()
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: viewModel.currentSpeed > 0 ? "stop.fill" : "play.fill")
                                    .font(.system(size: 8))
                                Text(viewModel.currentSpeed > 0 ? "Stop" : "Start")
                                    .font(.system(size: 9, weight: .medium))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.currentSpeed > 0 ? .red : .green)
                        .controlSize(.mini)
                    }
                }
            }

            // Speed sparkline
            SpeedSparkline(samples: viewModel.recentSpeedSamples)
                .padding(.horizontal, 2)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Live Stat Item

private struct LiveStatItem: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            Text(unit)
                .font(.system(size: 7))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
