import SwiftUI

struct DailySpinOverlay: View {
    let bonus: DailyBonus
    let onDismiss: () -> Void

    @State private var showMultiplier = false
    @State private var showXP = false
    @State private var scale: Double = 0.3
    @State private var rotation: Double = 0
    @State private var sparkleScale: Double = 0

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ZStack {
                    // Sparkle ring
                    ForEach(0..<8, id: \.self) { i in
                        Text("✨")
                            .font(.system(size: 10))
                            .offset(y: -32)
                            .rotationEffect(.degrees(Double(i) * 45 + rotation))
                            .scaleEffect(sparkleScale)
                            .opacity(sparkleScale)
                    }

                    Text("🎰")
                        .font(.system(size: 36))
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation * 0.3))
                }

                if showMultiplier {
                    Text(multiplierLabel)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(multiplierColor)
                        .transition(.scale.combined(with: .opacity))
                }

                if showXP {
                    VStack(spacing: 4) {
                        Text("Bonus dnia!")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("+\(bonus.bonusXP) XP")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.purple)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .onTapGesture { onDismiss() }
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.0
        }
        withAnimation(.easeOut(duration: 0.6)) {
            rotation = 360
        }
        withAnimation(.spring(response: 0.5).delay(0.3)) {
            sparkleScale = 1.0
        }
        withAnimation(.spring(response: 0.5).delay(0.4)) {
            showMultiplier = true
        }
        withAnimation(.spring(response: 0.5).delay(0.8)) {
            showXP = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            onDismiss()
        }
    }

    private var multiplierLabel: String {
        String(format: "×%.1f", bonus.multiplier)
    }

    private var multiplierColor: Color {
        switch bonus.multiplier {
        case 3.0: .yellow
        case 2.0: .orange
        default: .green
        }
    }
}
