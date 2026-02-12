import SwiftUI

struct MopsPetSection: View {
    private let workout = WorkoutManager.shared
    private let goals = GoalsManager.shared
    private let store = DataStore.shared
    private let profileManager = ProfileManager.shared
    private let xp = XPManager.shared

    @State private var animating = false
    @State private var didStartAnimation = false
    @State private var triviaText: String?
    @State private var showTrivia = false
    @State private var triviaTimer: DispatchWorkItem?
    @State private var currentTrick: PetTrick?
    @State private var showTrickAnimation = false

    // Ambient sparkles
    @State private var sparklePositions: [(x: CGFloat, y: CGFloat, scale: CGFloat, opacity: Double)] = []
    @State private var sparklePhase = false
    // Header icon
    @State private var pawPulse = false
    // XP bar shimmer
    @State private var xpShimmerOffset: CGFloat = -40
    // Trick float
    @State private var trickFloatY: CGFloat = 0
    @State private var trickOpacity: Double = 1
    // Star burst when ecstatic
    @State private var starBurst = false

    private var mood: MopsMood { MopsMood.current }
    private var petName: String { profileManager.activeProfile.petType.displayName }
    private var lifetimeKm: Double { MopsMood.lifetimeDistance }
    private var tier: PetEvolutionTier { PetEvolutionTier.tier(for: lifetimeKm) }

    private var todayKm: Double {
        goals.todayGoal?.completedDistance ?? 0
    }

    private var unlockedTricks: [PetTrick] {
        PetTrick.unlocked(for: xp.currentLevel.level)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.purple)
                    .scaleEffect(pawPulse ? 1.25 : 0.9)
                    .rotationEffect(.degrees(pawPulse ? 8 : -4))
                    .opacity(pawPulse ? 1.0 : 0.7)
                Text(tier == .base ? petName : "\(petName) \(tier.accessoryEmoji)")
                    .font(.system(size: 11, weight: .semibold))

                if mood == .ecstatic {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                        .scaleEffect(starBurst ? 1.3 : 0.8)
                        .rotationEffect(.degrees(starBurst ? 15 : -15))
                }

                Spacer()

                Text("Poz. \(xp.currentLevel.level)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
            }

            HStack(spacing: 10) {
                // Cartoon pet with ambient sparkles
                ZStack {
                    // Ambient sparkles around pet
                    ForEach(0..<sparklePositions.count, id: \.self) { i in
                        let sp = sparklePositions[i]
                        Text("✨")
                            .font(.system(size: 6))
                            .scaleEffect(sparklePhase ? sp.scale : sp.scale * 0.3)
                            .opacity(sparklePhase ? sp.opacity : sp.opacity * 0.2)
                            .offset(x: sp.x, y: sp.y)
                    }

                    CartoonPetView(
                        petType: profileManager.activeProfile.petType,
                        mood: mood,
                        tier: tier,
                        size: 56,
                        animating: animating
                    )
                    .modifier(PetAnimationModifier(mood: mood, animating: animating))

                    // Trick animation overlay — floats up and fades
                    if showTrickAnimation, let trick = currentTrick {
                        Text(trick.emoji)
                            .font(.system(size: 20))
                            .offset(y: -30 + trickFloatY)
                            .opacity(trickOpacity)
                            .scaleEffect(trickOpacity > 0.5 ? 1.0 : 0.6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Mood bubble or trivia
                    if showTrivia, let trivia = triviaText {
                        Text("💬 \(trivia)")
                            .font(.system(size: 9))
                            .foregroundStyle(.blue)
                            .lineLimit(2)
                            .transition(.opacity)
                    } else {
                        Text(mood.bubble)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    // XP bar with shimmer
                    HStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.purple.opacity(0.12))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(
                                        .linearGradient(
                                            colors: [.purple.opacity(0.7), .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(geo.size.width * xp.progressToNext, 4), height: 4)
                                    .overlay(
                                        // Shimmer highlight
                                        Capsule()
                                            .fill(
                                                .linearGradient(
                                                    colors: [.clear, .white.opacity(0.4), .clear],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 20, height: 4)
                                            .offset(x: xpShimmerOffset)
                                            .clipShape(Capsule())
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: 4)

                        Text("\(xp.totalXP) XP")
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    // Stats row
                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 7))
                                .foregroundStyle(.green)
                            Text(String(format: "%.1f km dziś", todayKm))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "map")
                                .font(.system(size: 7))
                                .foregroundStyle(.blue)
                            Text(String(format: "%.0f km łącznie", lifetimeKm))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Tricks row
                    if !unlockedTricks.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 7))
                                .foregroundStyle(.yellow)
                            Text("Sztuczki: \(unlockedTricks.count)/\(PetTrick.all.count)")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                            Spacer()
                            // Show unlocked trick emojis
                            HStack(spacing: 1) {
                                ForEach(unlockedTricks.suffix(5)) { trick in
                                    Text(trick.emoji)
                                        .font(.system(size: 8))
                                }
                            }
                        }
                    }
                }

                Spacer()
            }

            // Next evolution
            if let next = PetEvolutionTier.nextTier(after: tier) {
                let remaining = next.threshold - lifetimeKm
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 8))
                        .foregroundStyle(.orange)
                    Text("Następny: \(next.accessoryName) za \(String(format: "%.0f", remaining)) km")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .onAppear {
            guard !didStartAnimation else { return }
            didStartAnimation = true
            startAnimation()
            startAmbientSparkles()
            startPawPulse()
            startXPShimmer()
            if mood == .ecstatic {
                startStarBurst()
            }
        }
        .onChange(of: mood) { _, newMood in
            animating = false
            startAnimation()
            if newMood == .ecstatic {
                startStarBurst()
            }
        }
        .onTapGesture {
            if !unlockedTricks.isEmpty && !showTrivia {
                playRandomTrick()
            } else {
                loadTrivia()
            }
        }
    }

    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(animationForMood(mood)) {
                animating = true
            }
        }
    }

    private func startAmbientSparkles() {
        // Create random sparkle positions around pet
        sparklePositions = (0..<5).map { _ in
            (
                x: CGFloat.random(in: -32...32),
                y: CGFloat.random(in: -32...32),
                scale: CGFloat.random(in: 0.5...1.2),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            sparklePhase = true
        }
    }

    private func startPawPulse() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pawPulse = true
        }
    }

    private func startXPShimmer() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            xpShimmerOffset = 120
        }
    }

    private func startStarBurst() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            starBurst = true
        }
    }

    private func playRandomTrick() {
        guard let trick = unlockedTricks.randomElement() else { return }
        currentTrick = trick
        trickFloatY = 0
        trickOpacity = 1
        withAnimation(.spring(response: 0.3)) {
            showTrickAnimation = true
        }
        // Float upward and fade
        withAnimation(.easeOut(duration: 1.2)) {
            trickFloatY = -20
        }
        withAnimation(.easeIn(duration: 0.8).delay(0.7)) {
            trickOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showTrickAnimation = false }
            loadTrivia()
        }
    }

    private func loadTrivia() {
        triviaTimer?.cancel()

        let progress = VirtualRoute.progress(for: lifetimeKm)
        let route = VirtualRoute.allRoutes[progress.routeIndex]
        if let city = CityTrivia.lastVisitedCity(route: route, distanceOnRoute: progress.distanceOnRoute),
           let fact = CityTrivia.randomFact(for: city) {
            withAnimation(.easeInOut(duration: 0.3)) {
                triviaText = fact
                showTrivia = true
            }
            let timer = DispatchWorkItem { [self] in
                withAnimation { showTrivia = false }
            }
            triviaTimer = timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: timer)
        }
    }

    private func animationForMood(_ mood: MopsMood) -> Animation {
        switch mood {
        case .walking:
            .easeInOut(duration: 0.3).repeatForever(autoreverses: true)
        case .ecstatic:
            .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
        case .happy:
            .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        case .content:
            .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        case .waiting:
            .easeOut(duration: 0.6)
        case .sad:
            .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        }
    }
}

struct PetAnimationModifier: ViewModifier {
    let mood: MopsMood
    let animating: Bool

    func body(content: Content) -> some View {
        switch mood {
        case .walking:
            content
                .rotationEffect(.degrees(animating ? -10 : 10))
                .offset(x: animating ? -2 : 2, y: animating ? -4 : 2)
        case .ecstatic:
            content
                .scaleEffect(animating ? 1.15 : 0.95)
                .rotationEffect(.degrees(animating ? 5 : -5))
                .offset(y: animating ? -6 : 0)
        case .happy:
            content
                .rotationEffect(.degrees(animating ? 5 : -5))
                .offset(y: animating ? -2 : 1)
        case .content:
            content
                .scaleEffect(animating ? 1.04 : 0.98)
                .offset(y: animating ? -1 : 1)
        case .waiting:
            content
                .rotationEffect(.degrees(animating ? 8 : 0))
                .offset(y: animating ? -1 : 0)
        case .sad:
            content
                .offset(y: animating ? 3 : 0)
                .opacity(animating ? 0.65 : 0.85)
                .scaleEffect(animating ? 0.97 : 1.0)
        }
    }
}
