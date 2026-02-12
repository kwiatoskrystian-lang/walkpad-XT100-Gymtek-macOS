import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animating = false

    let emojis = ["🎉", "⭐", "🏆", "✨", "🎊", "💫", "🌟", "🥇"]

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .offset(x: animating ? p.endX : p.startX,
                            y: animating ? p.endY : p.startY)
                    .opacity(animating ? 0 : 1)
                    .rotationEffect(.degrees(animating ? p.rotation : 0))
                    .scaleEffect(animating ? p.endScale : 1.0)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            particles = (0..<30).map { _ in
                ConfettiParticle(
                    emoji: emojis.randomElement()!,
                    size: CGFloat.random(in: 8...20),
                    startX: CGFloat.random(in: -30...30),
                    startY: 0,
                    endX: CGFloat.random(in: -160...160),
                    endY: CGFloat.random(in: -220 ... -40),
                    rotation: Double.random(in: -540...540),
                    endScale: CGFloat.random(in: 0.3...0.8)
                )
            }
            withAnimation(.easeOut(duration: 1.8)) {
                animating = true
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let endScale: CGFloat
}
