import SwiftUI

struct TreadmillControlSection: View {
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "dial.medium.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.blue)
                Text("Sterowanie bieżnią")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                if let range = viewModel.supportedSpeedRange {
                    Text(String(format: "%.1f–%.1f km/h", range.minimum, range.maximum))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            // Speed control — centered
            HStack(spacing: 12) {
                Button {
                    viewModel.decreaseSpeed()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)

                VStack(spacing: 1) {
                    Text(String(format: "%.1f", viewModel.targetSpeed))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("km/h")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 50)

                Button {
                    viewModel.increaseSpeed()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }

            // Quick speed presets — centered
            HStack(spacing: 5) {
                ForEach([2.0, 3.0, 4.0, 5.0, 6.0], id: \.self) { speed in
                    Button {
                        viewModel.setTargetSpeed(speed)
                    } label: {
                        Text(String(format: "%.0f", speed))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .frame(width: 28, height: 20)
                            .background(
                                abs(viewModel.targetSpeed - speed) < 0.1
                                    ? Color.green.opacity(0.2)
                                    : Color.primary.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Start button — compact, matching app style
            Button {
                viewModel.startTreadmill()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                    Text("Uruchom bieżnię")
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.small)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.15), lineWidth: 0.5)
        )
    }
}
