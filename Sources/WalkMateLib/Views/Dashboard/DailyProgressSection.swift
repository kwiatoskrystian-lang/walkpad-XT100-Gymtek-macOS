import SwiftUI

struct DailyProgressSection: View {
    let viewModel: DashboardViewModel

    private var uncappedProgress: Double {
        guard viewModel.targetDistance > 0 else { return 0 }
        return viewModel.todayDistance / viewModel.targetDistance
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "target")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("Cel dzienny")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text(String(format: "%.0f%%", min(uncappedProgress, 9.99) * 100))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(uncappedProgress >= 1.0 ? .green : .secondary)
            }

            HStack(spacing: 14) {
                ProgressRing(
                    progress: uncappedProgress,
                    lineWidth: 6,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 6) {
                    // Distance
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", viewModel.todayDistance))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("/ \(String(format: "%.1f", viewModel.targetDistance)) km")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    // Status
                    if uncappedProgress >= 1.0 {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.green)
                            Text(String(format: "Cel osiągnięty! %.0f%%", uncappedProgress * 100))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                            Text(String(format: "Brakuje: %.1f km", viewModel.remainingDistance))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Streak
                    if viewModel.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                            Text("\(viewModel.currentStreak) dni z rzędu")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.orange)

                            if viewModel.streakShields > 0 {
                                HStack(spacing: 1) {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.cyan)
                                    Text("×\(viewModel.streakShields)")
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .foregroundStyle(.cyan)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.green.opacity(uncappedProgress >= 1.0 ? 0.3 : 0), lineWidth: 1)
        )
    }
}
