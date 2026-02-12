import SwiftUI

enum AppTab: String, CaseIterable {
    case dashboard = "Panel"
    case stats = "Statystyki"
    case history = "Historia"
    case achievements = "Osiągnięcia"
    case settings = "Ustawienia"

    var icon: String {
        switch self {
        case .dashboard: "house.fill"
        case .stats: "chart.bar.fill"
        case .history: "clock.fill"
        case .achievements: "trophy.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        VStack(spacing: 0) {
            // Tab content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .stats:
                    StatsView()
                case .history:
                    HistoryView()
                case .achievements:
                    AchievementsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Tab bar
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                                .symbolVariant(selectedTab == tab ? .fill : .none)

                            Text(tab.rawValue)
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .frame(width: 380, height: 520)
    }
}
