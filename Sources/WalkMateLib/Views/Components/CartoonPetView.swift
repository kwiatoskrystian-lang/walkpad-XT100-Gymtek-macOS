import SwiftUI

/// A multi-layered cartoon pet with rich lifelike micro-animations.
struct CartoonPetView: View {
    let petType: PetType
    let mood: MopsMood
    let tier: PetEvolutionTier
    let size: CGFloat
    let animating: Bool

    // Core animation states
    @State private var isBlinking = false
    @State private var breathScale: CGFloat = 1.0
    @State private var particleFloat: CGFloat = 0
    @State private var pupilX: CGFloat = 0
    @State private var earWiggle: Double = 0
    @State private var pawFidget: CGFloat = 0
    @State private var whiskerTwitch: Double = 0

    // NEW: Extra animation states
    @State private var tailWag: CGFloat = 0         // -1..1 tail sweep
    @State private var headBob: CGFloat = 0         // vertical nod
    @State private var isYawning = false            // mouth wide open
    @State private var isSneezing = false           // sneeze burst
    @State private var eyeSparkle = false           // star eyes for ecstatic
    @State private var stretchAmount: CGFloat = 1.0 // body stretch
    @State private var shiver: CGFloat = 0          // shiver offset for waiting
    @State private var tongueOut = false             // tongue sticks out randomly
    @State private var legKick: CGFloat = 0         // back leg kick for happy
    @State private var cheekPuff: CGFloat = 0       // cheeks puff during sneeze

    var body: some View {
        ZStack {
            // Soft glow (breathes + pulses with mood)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [moodGlowColor.opacity(0.2), moodGlowColor.opacity(0.05), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .scaleEffect(breathScale + 0.04)
                .opacity(0.8 + 0.2 * (breathScale - 1.0) * 50)

            // Pet body with breathing + stretch
            ZStack {
                switch petType {
                case .mops: pugBody
                case .raccoon: raccoonBody
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(x: stretchAmount, y: 2.0 - stretchAmount)
            .scaleEffect(breathScale)
            .offset(x: shiver, y: headBob)

            // Mood particles (floating gently)
            moodParticles
                .offset(y: -size * 0.38 + particleFloat)

            // Sneeze burst
            if isSneezing {
                sneezeBurst
            }

            // Yawn overlay
            if isYawning {
                yawnOverlay
            }

            // Evolution accessory
            if tier != .base {
                Text(tier.accessoryEmoji)
                    .font(.system(size: size * 0.2))
                    .offset(x: size * 0.28, y: -size * 0.32 + headBob)
                    .scaleEffect(breathScale)
                    .rotationEffect(.degrees(breathScale > 1.01 ? 5 : -5))
            }

            // Mood emoji (bobs gently)
            Text(mood.moodEmoji)
                .font(.system(size: size * 0.2))
                .offset(x: size * 0.38, y: -size * 0.38 + particleFloat * 0.5)
                .scaleEffect(0.9 + 0.1 * (1 + sin(particleFloat * 0.5)))
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .task { await blinkLoop() }
        .task { await breatheLoop() }
        .task { await particleLoop() }
        .task { await fidgetLoop() }
        .task { await tailWagLoop() }
        .task { await headBobLoop() }
        .task { await specialAnimLoop() }
    }

    // MARK: - Animation Loops

    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.5...4.0)))
            guard !Task.isCancelled else { return }
            isBlinking = true
            try? await Task.sleep(for: .milliseconds(110))
            guard !Task.isCancelled else { return }
            isBlinking = false
            // 30% chance of double blink
            if Double.random(in: 0...1) < 0.3 {
                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled else { return }
                isBlinking = true
                try? await Task.sleep(for: .milliseconds(90))
                guard !Task.isCancelled else { return }
                isBlinking = false
            }
        }
    }

    private func breatheLoop() async {
        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: 1.6)) { breathScale = 1.025 }
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 1.6)) { breathScale = 1.0 }
            try? await Task.sleep(for: .seconds(1.6))
        }
    }

    private func particleLoop() async {
        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: 2.2)) { particleFloat = -5 }
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 2.2)) { particleFloat = 5 }
            try? await Task.sleep(for: .seconds(2.2))
        }
    }

    private func tailWagLoop() async {
        while !Task.isCancelled {
            let speed: Double
            switch mood {
            case .ecstatic: speed = 0.2
            case .walking:  speed = 0.25
            case .happy:    speed = 0.4
            case .content:  speed = 0.8
            case .waiting:  speed = 1.2
            case .sad:      speed = 2.0
            }
            withAnimation(.easeInOut(duration: speed)) { tailWag = 1 }
            try? await Task.sleep(for: .seconds(speed))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: speed)) { tailWag = -1 }
            try? await Task.sleep(for: .seconds(speed))
        }
    }

    private func headBobLoop() async {
        while !Task.isCancelled {
            let dur = mood == .walking ? 0.3 : 1.0
            let amt: CGFloat = mood == .walking ? -2 : -0.8
            withAnimation(.easeInOut(duration: dur)) { headBob = amt }
            try? await Task.sleep(for: .seconds(dur))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: dur)) { headBob = 0 }
            try? await Task.sleep(for: .seconds(dur))
        }
    }

    /// Randomly triggers special animations: yawn, sneeze, stretch, shiver, tongue, leg kick.
    private func specialAnimLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 5.0...12.0)))
            guard !Task.isCancelled else { return }

            let choices: [Int]
            switch mood {
            case .ecstatic: choices = [0, 3, 4, 5]   // sneeze, eyeSparkle, tongue, legKick
            case .happy:    choices = [0, 1, 4, 5]    // sneeze, yawn, tongue, legKick
            case .walking:  choices = [0, 4]           // sneeze, tongue
            case .content:  choices = [1, 2, 4]        // yawn, stretch, tongue
            case .waiting:  choices = [1, 2, 6]        // yawn, stretch, shiver
            case .sad:      choices = [1, 6]           // yawn, shiver
            }

            guard let choice = choices.randomElement() else { continue }

            switch choice {
            case 0: // Sneeze
                withAnimation(.spring(response: 0.15)) { cheekPuff = 1 }
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                    isSneezing = true
                    cheekPuff = 0
                }
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) { isSneezing = false }

            case 1: // Yawn
                withAnimation(.easeInOut(duration: 0.4)) { isYawning = true }
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.3)) { isYawning = false }

            case 2: // Stretch
                withAnimation(.easeInOut(duration: 0.6)) { stretchAmount = 1.08 }
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { stretchAmount = 1.0 }

            case 3: // Eye sparkle (ecstatic only)
                withAnimation(.spring(response: 0.2)) { eyeSparkle = true }
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) { eyeSparkle = false }

            case 4: // Tongue flick
                tongueOut = true
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { return }
                tongueOut = false

            case 5: // Leg kick (happy/ecstatic)
                withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { legKick = 1 }
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { legKick = -1 }
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.2)) { legKick = 0 }

            case 6: // Shiver (waiting/sad)
                for _ in 0..<4 {
                    guard !Task.isCancelled else { return }
                    withAnimation(.linear(duration: 0.06)) { shiver = 1.5 }
                    try? await Task.sleep(for: .milliseconds(60))
                    withAnimation(.linear(duration: 0.06)) { shiver = -1.5 }
                    try? await Task.sleep(for: .milliseconds(60))
                }
                withAnimation(.linear(duration: 0.05)) { shiver = 0 }

            default: break
            }
        }
    }

    /// Randomly picks a micro-animation: look around, ear wiggle, paw fidget, or whisker/head twitch.
    private func fidgetLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.0...4.5)))
            guard !Task.isCancelled else { return }

            switch Int.random(in: 0...3) {
            case 0:
                let dir = CGFloat.random(in: -1...1)
                withAnimation(.easeInOut(duration: 0.3)) { pupilX = dir }
                try? await Task.sleep(for: .seconds(Double.random(in: 1.0...2.5)))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.3)) { pupilX = 0 }
            case 1:
                withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { earWiggle = 1 }
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3)) { earWiggle = 0 }
            case 2:
                withAnimation(.spring(response: 0.25)) { pawFidget = -1 }
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.25)) { pawFidget = 1 }
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3)) { pawFidget = 0 }
            case 3:
                withAnimation(.spring(response: 0.12, dampingFraction: 0.3)) { whiskerTwitch = 1 }
                try? await Task.sleep(for: .milliseconds(280))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.2)) { whiskerTwitch = 0 }
            default: break
            }
        }
    }

    // MARK: - Sneeze & Yawn Overlays

    private var sneezeBurst: some View {
        ZStack {
            // Sneeze particles flying out
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(0.6))
                    .frame(width: size * 0.03, height: size * 0.03)
                    .offset(
                        x: size * 0.15 + CGFloat(i) * size * 0.04,
                        y: CGFloat.random(in: -size * 0.08...size * 0.08)
                    )
            }
            Text("💨")
                .font(.system(size: size * 0.15))
                .offset(x: size * 0.3, y: -size * 0.05)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var yawnOverlay: some View {
        ZStack {
            // Wide open mouth
            Ellipse()
                .fill(.pink.opacity(0.6))
                .frame(width: size * 0.12, height: size * 0.1)
                .offset(y: size * 0.04)

            // Yawn text
            Text("😪")
                .font(.system(size: size * 0.12))
                .offset(x: size * 0.25, y: -size * 0.25)
                .opacity(0.7)
        }
    }

    // MARK: - Pug

    private var pugBody: some View {
        let tan = Color(red: 0.85, green: 0.75, blue: 0.58)
        let tanDark = Color(red: 0.78, green: 0.68, blue: 0.52)
        let dark = Color(red: 0.35, green: 0.25, blue: 0.18)

        return ZStack {
            // Curly tail (animated wag)
            Circle()
                .trim(from: 0.1, to: 0.8)
                .stroke(tanDark, lineWidth: size * 0.04)
                .frame(width: size * 0.14, height: size * 0.14)
                .rotationEffect(.degrees(Double(tailWag) * 30))
                .offset(x: -size * 0.32, y: -size * 0.02)

            // Back legs
            HStack(spacing: size * 0.18) {
                pugLeg(color: tanDark)
                    .offset(y: legKick * size * 0.03)
                pugLeg(color: tanDark)
                    .offset(y: -legKick * size * 0.02)
            }
            .offset(y: size * 0.3)

            // Body
            Ellipse()
                .fill(LinearGradient(colors: [tan, tanDark], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.65, height: size * 0.45)
                .offset(y: size * 0.05)

            // Belly patch
            Ellipse()
                .fill(Color(red: 0.92, green: 0.85, blue: 0.7).opacity(0.6))
                .frame(width: size * 0.35, height: size * 0.25)
                .offset(y: size * 0.1)

            // Head (tilts with whiskerTwitch, bobs)
            Circle()
                .fill(LinearGradient(colors: [tan.opacity(1.05), tanDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(y: -size * 0.15)
                .rotationEffect(.degrees(whiskerTwitch * 6))

            // Cheek puff (before sneeze)
            if cheekPuff > 0 {
                Circle()
                    .fill(tan.opacity(0.6))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(x: size * 0.18, y: -size * 0.02)
                    .scaleEffect(cheekPuff)
                Circle()
                    .fill(tan.opacity(0.6))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(x: -size * 0.18, y: -size * 0.02)
                    .scaleEffect(cheekPuff)
            }

            // Forehead wrinkles
            ForEach(0..<2, id: \.self) { i in
                Capsule()
                    .fill(dark.opacity(0.2))
                    .frame(width: size * 0.12, height: size * 0.01)
                    .offset(y: -size * 0.32 + CGFloat(i) * size * 0.025)
                    .rotationEffect(.degrees(whiskerTwitch * 6))
            }

            // Ears (floppy, wiggle!)
            pugEar(dark: dark)
                .offset(x: -size * 0.22, y: -size * 0.32)
                .rotationEffect(.degrees(-earWiggle * 12))
            pugEar(dark: dark)
                .offset(x: size * 0.22, y: -size * 0.32)
                .scaleEffect(x: -1)
                .rotationEffect(.degrees(earWiggle * 8))

            // Snout area
            Ellipse()
                .fill(dark)
                .frame(width: size * 0.28, height: size * 0.18)
                .offset(y: -size * 0.04)

            // Eyes (blink + look around + sparkle)
            pugEye(dark: dark).offset(x: -size * 0.13, y: -size * 0.2)
            pugEye(dark: dark).offset(x: size * 0.13, y: -size * 0.2)

            // Eye sparkles for ecstatic
            if eyeSparkle {
                Text("✦")
                    .font(.system(size: size * 0.08))
                    .foregroundStyle(.yellow)
                    .offset(x: -size * 0.09, y: -size * 0.23)
                Text("✦")
                    .font(.system(size: size * 0.06))
                    .foregroundStyle(.yellow)
                    .offset(x: size * 0.16, y: -size * 0.22)
            }

            // Eyebrows
            eyebrows(color: dark)

            // Nose
            Ellipse()
                .fill(.black)
                .frame(width: size * 0.1, height: size * 0.07)
                .offset(y: -size * 0.04)
                .scaleEffect(isSneezing ? 1.3 : 1.0)
            Circle()
                .fill(.white.opacity(0.25))
                .frame(width: size * 0.03)
                .offset(x: size * 0.02, y: -size * 0.05)

            // Mouth
            if isYawning {
                // Wide open yawn mouth
                Ellipse()
                    .fill(.pink.opacity(0.5))
                    .frame(width: size * 0.16, height: size * 0.12)
                    .offset(y: size * 0.04)
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .stroke(.black, lineWidth: size * 0.018)
                    .frame(width: size * 0.18, height: size * 0.14)
                    .offset(y: size * 0.02)
            } else {
                mouthView
            }

            // Tongue
            if tongueOut || mood == .happy || mood == .ecstatic || mood == .walking {
                Ellipse()
                    .fill(.pink)
                    .frame(
                        width: tongueOut ? size * 0.09 : size * 0.07,
                        height: tongueOut ? size * 0.08 : size * 0.055
                    )
                    .offset(
                        x: size * 0.015 + size * 0.008 * (breathScale > 1.01 ? 1 : -1),
                        y: tongueOut ? size * 0.08 : size * 0.06
                    )
            }

            // Blush (pulses with breathing)
            if mood == .happy || mood == .ecstatic {
                let blushOpacity = 0.25 + 0.1 * (breathScale > 1.01 ? 1 : 0)
                Circle().fill(.pink.opacity(blushOpacity))
                    .frame(width: size * 0.1).offset(x: -size * 0.2, y: -size * 0.08)
                Circle().fill(.pink.opacity(blushOpacity))
                    .frame(width: size * 0.1).offset(x: size * 0.2, y: -size * 0.08)
            }

            // Front paws (fidget!)
            HStack(spacing: size * 0.14) {
                pugPaw(color: tan).offset(x: pawFidget * size * 0.015)
                pugPaw(color: tan).offset(x: -pawFidget * size * 0.015)
            }
            .offset(y: size * 0.33)
        }
    }

    private func pugEar(dark: Color) -> some View {
        Ellipse()
            .fill(dark)
            .frame(width: size * 0.16, height: size * 0.13)
            .rotationEffect(.degrees(-25))
    }

    private func pugLeg(color: Color) -> some View {
        RoundedRectangle(cornerRadius: size * 0.04)
            .fill(color)
            .frame(width: size * 0.11, height: size * 0.16)
    }

    private func pugPaw(color: Color) -> some View {
        ZStack {
            Ellipse()
                .fill(color)
                .frame(width: size * 0.1, height: size * 0.06)
            HStack(spacing: size * 0.015) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(red: 0.35, green: 0.25, blue: 0.18).opacity(0.3))
                        .frame(width: size * 0.018)
                }
            }
            .offset(y: -size * 0.008)
        }
    }

    private func pugEye(dark: Color) -> some View {
        ZStack {
            if isBlinking || isSneezing {
                Capsule()
                    .fill(dark)
                    .frame(width: size * 0.12, height: size * 0.02)
            } else if isYawning {
                // Squinting during yawn
                Ellipse()
                    .fill(.white)
                    .frame(width: size * 0.14, height: size * 0.08)
                Circle()
                    .fill(.black)
                    .frame(width: size * 0.08)
                    .offset(y: -size * 0.005)
            } else {
                Ellipse()
                    .fill(.white)
                    .frame(width: size * 0.15, height: size * 0.15)
                Circle()
                    .fill(.black)
                    .frame(width: size * 0.1)
                    .offset(
                        x: (mood == .sad ? 0 : size * 0.01) + size * 0.02 * pupilX,
                        y: size * 0.005 * abs(pupilX)
                    )
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.04)
                    .offset(
                        x: size * 0.02 + size * 0.01 * pupilX,
                        y: -size * 0.025
                    )
                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: size * 0.02)
                    .offset(x: -size * 0.015, y: size * 0.015)
                if mood == .sad {
                    Rectangle()
                        .fill(Color(red: 0.85, green: 0.75, blue: 0.58))
                        .frame(width: size * 0.17, height: size * 0.06)
                        .offset(y: -size * 0.045)
                }
            }
        }
        .frame(width: size * 0.15, height: size * 0.15)
    }

    // MARK: - Raccoon

    private var raccoonBody: some View {
        let gray = Color(red: 0.58, green: 0.58, blue: 0.62)
        let grayDark = Color(red: 0.48, green: 0.48, blue: 0.52)
        let dark = Color(red: 0.2, green: 0.2, blue: 0.22)
        let light = Color(red: 0.85, green: 0.85, blue: 0.88)

        return ZStack {
            // Bushy tail (animated wag)
            raccoonTail(gray: gray, dark: dark)
                .offset(x: -size * 0.34, y: -size * 0.02)

            // Legs
            HStack(spacing: size * 0.18) {
                raccoonLeg(color: grayDark)
                    .offset(y: legKick * size * 0.03)
                raccoonLeg(color: grayDark)
                    .offset(y: -legKick * size * 0.02)
            }
            .offset(y: size * 0.3)

            // Body
            Ellipse()
                .fill(LinearGradient(colors: [gray, grayDark], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.65, height: size * 0.45)
                .offset(y: size * 0.05)

            // Belly patch
            Ellipse()
                .fill(light.opacity(0.5))
                .frame(width: size * 0.35, height: size * 0.25)
                .offset(y: size * 0.1)

            // Head
            Circle()
                .fill(LinearGradient(colors: [gray.opacity(1.05), grayDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(y: -size * 0.15)

            // Cheek puff (before sneeze)
            if cheekPuff > 0 {
                Circle()
                    .fill(gray.opacity(0.6))
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(x: size * 0.17, y: -size * 0.02)
                    .scaleEffect(cheekPuff)
                Circle()
                    .fill(gray.opacity(0.6))
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(x: -size * 0.17, y: -size * 0.02)
                    .scaleEffect(cheekPuff)
            }

            // Ears (pointed, wiggle!)
            raccoonEar(gray: gray, dark: dark)
                .offset(x: -size * 0.2, y: -size * 0.38)
                .rotationEffect(.degrees(-earWiggle * 10))
            raccoonEar(gray: gray, dark: dark)
                .offset(x: size * 0.2, y: -size * 0.38)
                .scaleEffect(x: -1)
                .rotationEffect(.degrees(earWiggle * 7))

            // Dark mask band
            Capsule()
                .fill(dark)
                .frame(width: size * 0.5, height: size * 0.13)
                .offset(y: -size * 0.18)

            // White snout stripe
            Ellipse()
                .fill(light)
                .frame(width: size * 0.16, height: size * 0.28)
                .offset(y: -size * 0.1)

            // Eyes (blink + look around)
            raccoonEye(dark: dark, gray: gray).offset(x: -size * 0.13, y: -size * 0.2)
            raccoonEye(dark: dark, gray: gray).offset(x: size * 0.13, y: -size * 0.2)

            // Eye sparkles for ecstatic
            if eyeSparkle {
                Text("✦")
                    .font(.system(size: size * 0.07))
                    .foregroundStyle(.yellow)
                    .offset(x: -size * 0.09, y: -size * 0.23)
                Text("✦")
                    .font(.system(size: size * 0.05))
                    .foregroundStyle(.yellow)
                    .offset(x: size * 0.15, y: -size * 0.22)
            }

            // Eyebrows
            eyebrows(color: dark)

            // Nose
            Ellipse()
                .fill(.black)
                .frame(width: size * 0.08, height: size * 0.06)
                .offset(y: -size * 0.04)
                .scaleEffect(isSneezing ? 1.3 : 1.0)
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: size * 0.025)
                .offset(x: size * 0.015, y: -size * 0.05)

            // Whiskers (twitch!)
            raccoonWhiskers(dark: dark)

            // Mouth
            if isYawning {
                Ellipse()
                    .fill(.pink.opacity(0.5))
                    .frame(width: size * 0.14, height: size * 0.1)
                    .offset(y: size * 0.04)
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .stroke(.black, lineWidth: size * 0.018)
                    .frame(width: size * 0.16, height: size * 0.12)
                    .offset(y: size * 0.02)
            } else {
                mouthView
            }

            // Tongue
            if tongueOut || mood == .ecstatic || mood == .walking {
                Ellipse()
                    .fill(.pink)
                    .frame(
                        width: tongueOut ? size * 0.08 : size * 0.06,
                        height: tongueOut ? size * 0.07 : size * 0.05
                    )
                    .offset(
                        x: size * 0.01 + size * 0.006 * (breathScale > 1.01 ? 1 : -1),
                        y: tongueOut ? size * 0.07 : size * 0.06
                    )
            }

            // Blush (pulses)
            if mood == .happy || mood == .ecstatic {
                let blushOpacity = 0.15 + 0.1 * (breathScale > 1.01 ? 1 : 0)
                Circle().fill(.pink.opacity(blushOpacity))
                    .frame(width: size * 0.09).offset(x: -size * 0.2, y: -size * 0.07)
                Circle().fill(.pink.opacity(blushOpacity))
                    .frame(width: size * 0.09).offset(x: size * 0.2, y: -size * 0.07)
            }

            // Front paws (fidget!)
            HStack(spacing: size * 0.14) {
                raccoonPaw(gray: gray, dark: dark).offset(x: pawFidget * size * 0.015)
                raccoonPaw(gray: gray, dark: dark).offset(x: -pawFidget * size * 0.015)
            }
            .offset(y: size * 0.33)
        }
    }

    private func raccoonEar(gray: Color, dark: Color) -> some View {
        ZStack {
            Triangle()
                .fill(dark)
                .frame(width: size * 0.14, height: size * 0.15)
            Triangle()
                .fill(.pink.opacity(0.3))
                .frame(width: size * 0.07, height: size * 0.08)
                .offset(y: size * 0.015)
        }
        .rotationEffect(.degrees(-10))
    }

    private func raccoonLeg(color: Color) -> some View {
        RoundedRectangle(cornerRadius: size * 0.04)
            .fill(color)
            .frame(width: size * 0.11, height: size * 0.16)
    }

    private func raccoonPaw(gray: Color, dark: Color) -> some View {
        ZStack {
            Ellipse()
                .fill(dark)
                .frame(width: size * 0.11, height: size * 0.06)
            HStack(spacing: size * 0.01) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(dark.opacity(0.8))
                        .frame(width: size * 0.015, height: size * 0.03)
                }
            }
            .offset(y: -size * 0.015)
        }
    }

    private func raccoonTail(gray: Color, dark: Color) -> some View {
        ZStack {
            Capsule()
                .fill(gray)
                .frame(width: size * 0.1, height: size * 0.25)
                .rotationEffect(.degrees(Double(tailWag) * 25))
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(dark)
                    .frame(width: size * 0.1, height: size * 0.025)
                    .offset(y: CGFloat(i) * size * 0.045 - size * 0.07)
                    .rotationEffect(.degrees(Double(tailWag) * 25))
            }
            Circle()
                .fill(dark)
                .frame(width: size * 0.08)
                .offset(y: -size * 0.1)
                .rotationEffect(.degrees(Double(tailWag) * 25))
        }
    }

    private func raccoonWhiskers(dark: Color) -> some View {
        Group {
            Capsule().fill(Color.black.opacity(0.15))
                .frame(width: size * 0.12, height: size * 0.008)
                .rotationEffect(.degrees(-10 + whiskerTwitch * 6))
                .offset(x: -size * 0.16, y: -size * 0.02)
            Capsule().fill(Color.black.opacity(0.15))
                .frame(width: size * 0.1, height: size * 0.008)
                .rotationEffect(.degrees(5 - whiskerTwitch * 4))
                .offset(x: -size * 0.15, y: size * 0.0)
            Capsule().fill(Color.black.opacity(0.15))
                .frame(width: size * 0.12, height: size * 0.008)
                .rotationEffect(.degrees(10 - whiskerTwitch * 6))
                .offset(x: size * 0.16, y: -size * 0.02)
            Capsule().fill(Color.black.opacity(0.15))
                .frame(width: size * 0.1, height: size * 0.008)
                .rotationEffect(.degrees(-5 + whiskerTwitch * 4))
                .offset(x: size * 0.15, y: size * 0.0)
        }
    }

    private func raccoonEye(dark: Color, gray: Color) -> some View {
        ZStack {
            if isBlinking || isSneezing {
                Capsule()
                    .fill(dark)
                    .frame(width: size * 0.11, height: size * 0.02)
            } else if isYawning {
                Ellipse()
                    .fill(.white)
                    .frame(width: size * 0.13, height: size * 0.07)
                Circle()
                    .fill(.black)
                    .frame(width: size * 0.07)
                    .offset(y: -size * 0.005)
            } else {
                Ellipse()
                    .fill(.white)
                    .frame(width: size * 0.14, height: size * 0.14)
                Circle()
                    .fill(.black)
                    .frame(width: size * 0.1)
                    .offset(
                        x: (mood == .sad ? 0 : size * 0.01) + size * 0.02 * pupilX,
                        y: size * 0.005 * abs(pupilX)
                    )
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.04)
                    .offset(
                        x: size * 0.02 + size * 0.01 * pupilX,
                        y: -size * 0.025
                    )
                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: size * 0.02)
                    .offset(x: -size * 0.015, y: size * 0.015)
                if mood == .sad {
                    Rectangle()
                        .fill(gray)
                        .frame(width: size * 0.16, height: size * 0.06)
                        .offset(y: -size * 0.045)
                }
            }
        }
        .frame(width: size * 0.14, height: size * 0.14)
    }

    // MARK: - Shared Components

    private func eyebrows(color: Color) -> some View {
        Group {
            switch mood {
            case .ecstatic, .happy:
                Capsule().fill(color.opacity(0.6))
                    .frame(width: size * 0.08, height: size * 0.015)
                    .rotationEffect(.degrees(-12))
                    .offset(x: -size * 0.13, y: -size * 0.3)
                Capsule().fill(color.opacity(0.6))
                    .frame(width: size * 0.08, height: size * 0.015)
                    .rotationEffect(.degrees(12))
                    .offset(x: size * 0.13, y: -size * 0.3)
            case .sad:
                Capsule().fill(color.opacity(0.6))
                    .frame(width: size * 0.08, height: size * 0.015)
                    .rotationEffect(.degrees(18))
                    .offset(x: -size * 0.13, y: -size * 0.28)
                Capsule().fill(color.opacity(0.6))
                    .frame(width: size * 0.08, height: size * 0.015)
                    .rotationEffect(.degrees(-18))
                    .offset(x: size * 0.13, y: -size * 0.28)
            default:
                EmptyView()
            }
        }
    }

    private var mouthView: some View {
        Group {
            switch mood {
            case .happy, .ecstatic, .walking:
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .stroke(.black, lineWidth: size * 0.018)
                    .frame(width: size * 0.14, height: size * 0.1)
                    .offset(y: size * 0.02)
            case .sad:
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(.black, lineWidth: size * 0.018)
                    .frame(width: size * 0.1, height: size * 0.06)
                    .offset(y: size * 0.06)
            default:
                Capsule()
                    .fill(.black)
                    .frame(width: size * 0.1, height: size * 0.012)
                    .offset(y: size * 0.03)
            }
        }
    }

    private var moodParticles: some View {
        Group {
            switch mood {
            case .ecstatic:
                HStack(spacing: size * 0.06) {
                    Text("⭐").font(.system(size: size * 0.14))
                        .offset(y: animating ? -size * 0.14 : 0)
                        .rotationEffect(.degrees(animating ? 20 : -20))
                    Text("✨").font(.system(size: size * 0.11))
                        .offset(y: animating ? -size * 0.07 : size * 0.07)
                        .scaleEffect(animating ? 1.2 : 0.8)
                    Text("⭐").font(.system(size: size * 0.14))
                        .offset(y: animating ? -size * 0.14 : 0)
                        .rotationEffect(.degrees(animating ? -20 : 20))
                    Text("💫").font(.system(size: size * 0.09))
                        .offset(y: animating ? -size * 0.1 : size * 0.03)
                        .opacity(animating ? 1 : 0.4)
                }
            case .walking:
                HStack(spacing: size * 0.05) {
                    Text("💨").font(.system(size: size * 0.11))
                        .opacity(animating ? 0.9 : 0.3)
                        .offset(x: animating ? -size * 0.03 : 0)
                    Text("💨").font(.system(size: size * 0.09))
                        .offset(y: size * 0.04)
                        .opacity(animating ? 0.4 : 0.8)
                        .offset(x: animating ? -size * 0.05 : 0)
                    Text("💨").font(.system(size: size * 0.07))
                        .offset(y: size * 0.02)
                        .opacity(animating ? 0.7 : 0.2)
                        .offset(x: animating ? -size * 0.02 : size * 0.02)
                }
                .offset(x: -size * 0.38)
            case .happy:
                HStack(spacing: size * 0.08) {
                    Text("♪").font(.system(size: size * 0.13))
                        .offset(y: animating ? -size * 0.1 : 0)
                        .rotationEffect(.degrees(animating ? -15 : 15))
                    Text("♫").font(.system(size: size * 0.11))
                        .offset(y: animating ? 0 : -size * 0.1)
                        .rotationEffect(.degrees(animating ? 15 : -15))
                    Text("♪").font(.system(size: size * 0.09))
                        .offset(y: animating ? -size * 0.06 : size * 0.02)
                        .rotationEffect(.degrees(animating ? -8 : 8))
                    Text("💕").font(.system(size: size * 0.07))
                        .offset(y: animating ? -size * 0.12 : -size * 0.04)
                        .opacity(animating ? 0.8 : 0.3)
                }
            case .sad:
                ZStack {
                    Text("💧").font(.system(size: size * 0.11))
                        .offset(x: size * 0.2, y: animating ? size * 0.35 : size * 0.15)
                        .opacity(animating ? 0.2 : 0.9)
                    Text("💧").font(.system(size: size * 0.08))
                        .offset(x: -size * 0.15, y: animating ? size * 0.28 : size * 0.12)
                        .opacity(animating ? 0.5 : 0.3)
                    Text("💧").font(.system(size: size * 0.06))
                        .offset(x: size * 0.08, y: animating ? size * 0.32 : size * 0.18)
                        .opacity(animating ? 0.1 : 0.6)
                }
            case .content:
                HStack(spacing: size * 0.08) {
                    Text("😊").font(.system(size: size * 0.1))
                        .opacity(animating ? 0.8 : 0.4)
                        .scaleEffect(animating ? 1.15 : 0.85)
                    Text("💤").font(.system(size: size * 0.08))
                        .opacity(animating ? 0.5 : 0.2)
                        .offset(y: animating ? -size * 0.03 : size * 0.02)
                    Text("💤").font(.system(size: size * 0.06))
                        .opacity(animating ? 0.3 : 0.1)
                        .offset(x: size * 0.05, y: animating ? -size * 0.06 : 0)
                }
            default:
                EmptyView()
            }
        }
    }

    private var moodGlowColor: Color {
        switch mood {
        case .walking:  .green
        case .ecstatic: .yellow
        case .happy:    .green
        case .content:  .blue
        case .waiting:  .gray
        case .sad:      .blue
        }
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
