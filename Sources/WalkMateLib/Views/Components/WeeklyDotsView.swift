import SwiftUI

struct WeeklyDotsView: View {
    let dayStatus: [Bool] // 7 elements, Mon-Sun
    let completedSessions: Int
    let target: Int

    private let dayLabels = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        Text(dayLabels[index])
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(dotColor(for: index))
                            .frame(width: 14, height: 14)
                            .overlay {
                                if dayStatus[index] {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                if isToday(index) {
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: 2)
                                        .frame(width: 18, height: 18)
                                }
                            }
                    }
                }
            }

            Text("\(completedSessions)/\(target) sesji w tym tygodniu")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func dotColor(for index: Int) -> Color {
        if dayStatus[index] {
            return .green
        }
        return .gray.opacity(0.3)
    }

    private func isToday(_ index: Int) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: .now)
        // Convert Sunday=1...Saturday=7 to Monday=0...Sunday=6
        let mondayBasedIndex = (weekday + 5) % 7
        return mondayBasedIndex == index
    }
}
