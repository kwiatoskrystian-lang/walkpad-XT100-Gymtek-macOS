import SwiftUI

struct AchievementsView: View {
    @State private var viewModel = AchievementsViewModel()

    private var categories: [(key: String, label: String, icon: String, color: Color)] {
        [
            ("distance", "Dystans", "figure.walk", .blue),
            ("streak", "Passa", "flame.fill", .orange),
            ("speed", "Prędkość", "bolt.fill", .cyan),
            ("sessions", "Sesje", "target", .green),
            ("seasonal", "Sezonowe", "leaf.fill", .purple),
        ]
    }

    private func achievements(for category: String) -> [Achievement] {
        viewModel.achievements.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.yellow)
                    Text("Osiągnięcia")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text("\(viewModel.unlockedCount)/\(viewModel.totalCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 2)

                // Progress bar
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.gray.opacity(0.15))
                            Capsule()
                                .fill(
                                    .linearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: viewModel.totalCount > 0
                                    ? geo.size.width * CGFloat(viewModel.unlockedCount) / CGFloat(viewModel.totalCount)
                                    : 0
                                )
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text(String(format: "%.0f%% ukończone", viewModel.totalCount > 0
                            ? Double(viewModel.unlockedCount) / Double(viewModel.totalCount) * 100
                            : 0))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let next = viewModel.achievements.first(where: { !$0.isUnlocked }) {
                            Text("Następne: \(next.name)")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal, 2)

                // Categories
                ForEach(categories, id: \.key) { cat in
                    let items = achievements(for: cat.key)
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            // Category header
                            HStack(spacing: 5) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 10))
                                    .foregroundStyle(cat.color)
                                Text(cat.label)
                                    .font(.system(size: 11, weight: .semibold))

                                Spacer()

                                let unlocked = items.filter(\.isUnlocked).count
                                Text("\(unlocked)/\(items.count)")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            // Achievement grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ], spacing: 8) {
                                ForEach(items) { achievement in
                                    AchievementCard(
                                        achievement: achievement,
                                        viewModel: viewModel,
                                        categoryColor: cat.color
                                    )
                                }
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear { viewModel.refresh() }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let viewModel: AchievementsViewModel
    let categoryColor: Color

    @State private var showShimmer = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? categoryColor.opacity(0.15)
                            : Color.gray.opacity(0.06)
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: achievement.isUnlocked ? achievement.iconName : "lock.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        achievement.isUnlocked
                            ? categoryColor
                            : Color.gray.opacity(0.3)
                    )
            }

            Text(achievement.name)
                .font(.system(size: 9, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundStyle(achievement.isUnlocked ? Color.primary : Color.secondary.opacity(0.5))

            if achievement.isUnlocked {
                Text(viewModel.formattedDate(achievement.unlockedDate))
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
            } else {
                Text(achievement.achievementDescription)
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(
            achievement.isUnlocked
                ? AnyShapeStyle(categoryColor.opacity(0.04))
                : AnyShapeStyle(Color.clear),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    achievement.isUnlocked
                        ? categoryColor.opacity(0.15)
                        : Color.gray.opacity(0.08),
                    lineWidth: 1
                )
        )
        .overlay {
            if showShimmer {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .transition(.opacity)
            }
        }
        .onAppear {
            if let unlockDate = achievement.unlockedDate,
               Date().timeIntervalSince(unlockDate) < 60
            {
                withAnimation(.easeInOut(duration: 1).repeatCount(3)) {
                    showShimmer = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showShimmer = false
                }
            }
        }
    }
}
