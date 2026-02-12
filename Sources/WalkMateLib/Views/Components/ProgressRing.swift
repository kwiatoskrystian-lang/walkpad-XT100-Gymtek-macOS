import SwiftUI

struct ProgressRing: View {
    let progress: Double // can exceed 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    var showLabel: Bool = true

    @State private var animatedProgress: Double = 0
    @State private var shimmerRotation: Double = 0
    @State private var glowPulse: Double = 0

    private var ringFill: Double {
        let p = animatedProgress
        if p >= 1.0 { return 1.0 }
        return max(p, 0)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(ringColor.opacity(0.15), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: ringFill)
                .stroke(
                    AngularGradient(
                        colors: [ringColor.opacity(0.5), ringColor, ringColor.opacity(0.8)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * ringFill)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Shimmer arc (rotating highlight)
            if animatedProgress > 0.05 {
                Circle()
                    .trim(from: 0, to: 0.08)
                    .stroke(.white.opacity(0.35), style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round))
                    .rotationEffect(.degrees(shimmerRotation - 90))
            }

            // Over-100% glow ring (pulsing!)
            if animatedProgress > 1.0 {
                Circle()
                    .stroke(ringColor.opacity(0.2 + glowPulse * 0.25), lineWidth: lineWidth + 5)
                    .blur(radius: 4)
                Circle()
                    .stroke(ringColor.opacity(0.1 + glowPulse * 0.15), lineWidth: lineWidth + 8)
                    .blur(radius: 6)
            }

            // Dot at progress tip
            if animatedProgress > 0.05 && animatedProgress < 1.0 {
                Circle()
                    .fill(.white)
                    .frame(width: lineWidth * 0.5, height: lineWidth * 0.5)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * ringFill - 90))
            }

            if showLabel {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(animatedProgress >= 1.0 ? ringColor : .primary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                shimmerRotation = 360
            }
            if progress >= 1.0 {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowPulse = 1
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
            if newValue >= 1.0 && glowPulse == 0 {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowPulse = 1
                }
            }
        }
    }

    private var ringColor: Color {
        if animatedProgress >= 1.0 { return .green }
        switch animatedProgress {
        case ..<0.33: return .red
        case 0.33..<0.66: return .orange
        default: return .green
        }
    }
}
