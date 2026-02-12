import Charts
import SwiftUI

struct SpeedSparkline: View {
    let samples: [SpeedSample]

    private var chartSamples: [SpeedSample] {
        guard !samples.isEmpty else { return [] }
        var data = samples
        // If only 1 sample, add a zero-start so the line has 2 points
        if data.count == 1, let first = data.first {
            data.insert(SpeedSample(timestamp: max(first.timestamp - 10, 0), speed: 0), at: 0)
        }
        return data
    }

    var body: some View {
        ZStack {
            if chartSamples.count >= 2 {
                Chart(chartSamples) { sample in
                    AreaMark(
                        x: .value("Czas", sample.timestamp),
                        y: .value("Prędkość", sample.speed)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Czas", sample.timestamp),
                        y: .value("Prędkość", sample.speed)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            } else {
                // Placeholder — keeps layout stable
                HStack {
                    Spacer()
                    Text("Zbieranie danych...")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
    }
}
