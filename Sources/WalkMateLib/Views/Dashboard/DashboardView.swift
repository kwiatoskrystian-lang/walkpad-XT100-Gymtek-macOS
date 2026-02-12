import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var showConfetti = false
    @State private var lastGoalState = false
    @State private var pendingBonus: DailyBonus?

    private var goalAchieved: Bool {
        GoalsManager.shared.dailyProgress >= 1.0
    }

    var body: some View {
        ZStack {
            TimeOfDayTint()

            ScrollView {
                VStack(spacing: 10) {
                    // Header
                    HStack(spacing: 6) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.blue)
                        Text("Panel")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        ConnectionStatusPill(
                            state: viewModel.connectionState,
                            deviceName: viewModel.deviceName
                        )
                    }
                    .padding(.horizontal, 2)

                    // Bluetooth warning
                    if let message = viewModel.bluetoothState.statusMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            Text(message)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }

                    // Live workout (visible only when active)
                    if viewModel.isWorkoutActive {
                        LiveWorkoutSection(viewModel: viewModel)
                    }

                    // Treadmill control (connected but no workout)
                    if !viewModel.isWorkoutActive && viewModel.canControlTreadmill {
                        TreadmillControlSection(viewModel: viewModel)
                    }

                    MopsPetSection()
                    RivalrySection()
                    DailyProgressSection(viewModel: viewModel)
                    WeeklyChallengeSection()
                    InsightsSection()
                    RouteProgressSection()
                    WeeklyChartSection()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }

            // Daily spin overlay
            if let bonus = pendingBonus {
                DailySpinOverlay(bonus: bonus) {
                    withAnimation { pendingBonus = nil }
                    DailyBonusManager.shared.clearPendingBonus()
                }
            }
        }
        .onChange(of: goalAchieved) { old, new in
            if !old && new {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { showConfetti = false }
                }
            }
        }
        .onChange(of: DailyBonusManager.shared.pendingBonus?.date) { _, _ in
            if let bonus = DailyBonusManager.shared.pendingBonus {
                withAnimation { pendingBonus = bonus }
            }
        }
    }
}
