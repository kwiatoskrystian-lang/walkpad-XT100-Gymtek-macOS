import SwiftUI

struct RivalrySection: View {
    private let profileManager = ProfileManager.shared

    private var profiles: [UserProfile] { profileManager.profiles }

    private var weeklyData: [(profile: UserProfile, distance: Double)] {
        let calendar = Calendar.current
        var weekStart = calendar.startOfDay(for: .now)
        while calendar.component(.weekday, from: weekStart) != 2 {
            weekStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
        }

        return profiles.map { profile in
            let dir = profileManager.storageDirectory(for: profile)
            let workouts = DataStore.loadWorkouts(from: dir)
            let weekKm = workouts
                .filter { $0.endDate != nil && $0.startDate >= weekStart }
                .reduce(0.0) { $0 + $1.distance }
            return (profile, weekKm)
        }
    }

    var body: some View {
        if profiles.count >= 2 {
            let data = weeklyData
            let maxDistance = data.map(\.distance).max() ?? 1
            let leaderId = data.max(by: { $0.distance < $1.distance })?.profile.id

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.purple)
                    Text("Rywalizacja tygodniowa")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text("⚔️")
                        .font(.system(size: 11))
                }

                ForEach(Array(data.enumerated()), id: \.element.profile.id) { idx, entry in
                    let isLeader = entry.profile.id == leaderId && entry.distance > 0
                    let fraction = maxDistance > 0 ? entry.distance / maxDistance : 0

                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            if isLeader {
                                Text("👑")
                                    .font(.system(size: 9))
                            }
                            Image(systemName: entry.profile.petType.icon)
                                .font(.system(size: 9))
                                .foregroundStyle(isLeader ? .green : .secondary)
                            Text(entry.profile.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                        }
                        .frame(width: 90, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.primary.opacity(0.06))
                                    .frame(height: 8)

                                Capsule()
                                    .fill(
                                        .linearGradient(
                                            colors: isLeader
                                                ? [.green.opacity(0.5), .green.opacity(0.8), .green]
                                                : [.blue.opacity(0.3), .blue.opacity(0.5), .blue.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(geo.size.width * fraction, 4), height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text(String(format: "%.1f km", entry.distance))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(isLeader ? .green : .secondary)
                            .frame(width: 45, alignment: .trailing)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
