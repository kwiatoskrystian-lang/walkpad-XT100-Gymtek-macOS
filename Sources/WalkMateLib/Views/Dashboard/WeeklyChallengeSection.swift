import SwiftUI

struct WeeklyChallengeSection: View {
    private let manager = ChallengeManager.shared

    var body: some View {
        let challenges = manager.currentChallenges
        if !challenges.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "flag.2.crossed.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("Wyzwania tygodniowe")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text("\(manager.completedCount)/\(challenges.count)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                }

                ForEach(Array(challenges.enumerated()), id: \.element.id) { idx, challenge in
                    ChallengeRow(challenge: challenge, index: idx)
                }

                if manager.totalBonusXP > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8))
                            .foregroundStyle(.purple)
                        Text("+\(manager.totalBonusXP) XP z wyzwań")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.purple)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct ChallengeRow: View {
    let challenge: WeeklyChallenge
    let index: Int

    private var progressFraction: Double {
        guard challenge.target > 0 else { return 0 }
        return min(challenge.progress / challenge.target, 1.0)
    }

    private var progressText: String {
        switch challenge.type {
        case .distanceSingle, .distanceTotal:
            return String(format: "%.1f/%.0f km", challenge.progress, challenge.target)
        case .speed:
            return String(format: "%.1f/%.1f km/h", challenge.progress, challenge.target)
        case .sessions:
            return "\(Int(challenge.progress))/\(Int(challenge.target))"
        case .duration:
            return "\(Int(challenge.progress))/\(Int(challenge.target)) min"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(challenge.isCompleted ? .green.opacity(0.15) : .orange.opacity(0.1))
                    .frame(width: 26, height: 26)

                Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : challenge.iconName)
                    .font(.system(size: 11))
                    .foregroundStyle(challenge.isCompleted ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(challenge.name)
                        .font(.system(size: 10, weight: .medium))
                        .strikethrough(challenge.isCompleted)
                        .foregroundStyle(challenge.isCompleted ? .secondary : .primary)
                    Spacer()
                    Text("+\(challenge.xpReward) XP")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(challenge.isCompleted ? .green : .orange)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.primary.opacity(0.06))
                            .frame(height: 4)
                        Capsule()
                            .fill(
                                challenge.isCompleted
                                    ? AnyShapeStyle(.linearGradient(
                                        colors: [.green.opacity(0.6), .green],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    : AnyShapeStyle(.linearGradient(
                                        colors: [.orange.opacity(0.6), .orange],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                            )
                            .frame(width: max(geo.size.width * progressFraction, 4), height: 4)
                    }
                }
                .frame(height: 4)

                Text(challenge.isCompleted ? "Ukończone!" : progressText)
                    .font(.system(size: 8))
                    .foregroundStyle(challenge.isCompleted ? .green : .secondary)
            }
        }
    }
}
