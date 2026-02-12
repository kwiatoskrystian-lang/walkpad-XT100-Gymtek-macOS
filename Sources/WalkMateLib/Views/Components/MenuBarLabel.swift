import SwiftUI
import AppKit

struct MenuBarLabel: View {
    private let goals = GoalsManager.shared
    private let workout = WorkoutManager.shared
    private let profileManager = ProfileManager.shared

    @State private var runFrame = 0
    @State private var idleFrame = 0
    @State private var eyesClosed = false
    @State private var microBounce = false
    @State private var tailWagPhase = false     // separate tail wag cycle
    @State private var tongueFlicker = false    // tongue in/out while running
    @State private var celebrationFrame = 0     // goal celebration particles

    private var todayKm: Double {
        let raw = goals.todayGoal?.completedDistance ?? 0
        return (raw * 10).rounded(.down) / 10
    }

    private var targetKm: Double {
        goals.todayGoal?.targetDistance ?? AppSettings.shared.dailyGoalDistance
    }

    private var progress: Double {
        guard targetKm > 0 else { return 0 }
        return min(todayKm / targetKm, 1.0)
    }

    private var goalComplete: Bool { progress >= 1.0 }

    private var menuBarText: String {
        if workout.isWorkoutActive {
            let speed = String(format: "%.1f", workout.currentSpeed)
            let dist = String(format: "%.2f", workout.currentDistance)
            return "\(speed) km/h · \(dist) km · \(workout.steps)"
        }
        return String(format: "%.1f km", todayKm)
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(nsImage: renderMenuBar())

            Text(menuBarText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
        .task(id: workout.isWorkoutActive) {
            if workout.isWorkoutActive {
                // Running animation
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(300))
                    runFrame = runFrame == 0 ? 1 : 0
                    microBounce.toggle()
                    tongueFlicker.toggle()
                }
            } else {
                // Idle animation — cycle through poses
                runFrame = 0
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(3000))
                    idleFrame = (idleFrame + 1) % 8
                }
            }
        }
        .task {
            // Eye blink timer with double blink
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3.0...5.0)))
                guard !Task.isCancelled else { return }
                eyesClosed = true
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                eyesClosed = false
                // 25% double blink
                if Double.random(in: 0...1) < 0.25 {
                    try? await Task.sleep(for: .milliseconds(200))
                    guard !Task.isCancelled else { return }
                    eyesClosed = true
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                    eyesClosed = false
                }
            }
        }
        .task {
            // Tail wag timer (faster when happy/ecstatic)
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(workout.isWorkoutActive ? 250 : 500))
                tailWagPhase.toggle()
            }
        }
        .task {
            // Celebration sparkle when goal complete
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(600))
                if goalComplete {
                    celebrationFrame = (celebrationFrame + 1) % 4
                } else {
                    celebrationFrame = 0
                }
            }
        }
    }

    // MARK: - Render

    private func renderMenuBar() -> NSImage {
        let barW: CGFloat = 56
        let barH: CGFloat = 3
        let barX: CGFloat = 2
        let barY: CGFloat = 2
        let imgW: CGFloat = 62
        let imgH: CGFloat = 22

        let img = NSImage(size: NSSize(width: imgW, height: imgH))
        img.lockFocus()

        // Bar background
        let bg = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: barW, height: barH),
                              xRadius: barH / 2, yRadius: barH / 2)
        NSColor.gray.withAlphaComponent(0.25).setFill()
        bg.fill()

        // Bar fill
        let fillW = max(barW * CGFloat(progress), progress > 0 ? barH : 0)
        let fill = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: fillW, height: barH),
                                xRadius: barH / 2, yRadius: barH / 2)
        barFillColor.setFill()
        fill.fill()

        // Glow dot at leading edge
        if fillW > barH {
            NSColor.white.withAlphaComponent(0.7).setFill()
            NSBezierPath(ovalIn: NSRect(x: barX + fillW - 2, y: barY, width: 3, height: 3)).fill()
        }

        // Celebration sparkles when goal complete
        if goalComplete {
            drawCelebration(barX: barX, barY: barY, barW: barW)
        }

        // Pet position — walks along the bar
        let petW: CGFloat = 16
        let petX = barX + CGFloat(progress) * (barW - petW)
        let petY = barY + barH

        let tier = PetEvolutionTier.tier(for: MopsMood.lifetimeDistance)

        if workout.isWorkoutActive {
            switch profileManager.activeProfile.petType {
            case .mops:
                drawPugRunning(at: NSPoint(x: petX, y: petY), frame: runFrame)
            case .raccoon:
                drawRaccoonRunning(at: NSPoint(x: petX, y: petY), frame: runFrame)
            }
        } else {
            switch profileManager.activeProfile.petType {
            case .mops:
                drawPugIdle(at: NSPoint(x: petX, y: petY), activity: idleFrame)
            case .raccoon:
                drawRaccoonIdle(at: NSPoint(x: petX, y: petY), activity: idleFrame)
            }
        }

        drawAccessory(at: NSPoint(x: petX, y: petY), tier: tier)

        img.unlockFocus()
        img.isTemplate = false
        return img
    }

    // MARK: - Celebration Particles

    private func drawCelebration(barX: CGFloat, barY: CGFloat, barW: CGFloat) {
        let positions: [(CGFloat, CGFloat)] = [
            (barX + 10, barY + 6),
            (barX + barW * 0.4, barY + 8),
            (barX + barW * 0.7, barY + 5),
            (barX + barW - 5, barY + 7),
        ]
        let colors: [NSColor] = [.systemYellow, .systemGreen, .systemOrange, .systemPink]
        let visible = celebrationFrame

        for i in 0..<positions.count {
            let alpha: CGFloat = (i == visible || i == (visible + 2) % 4) ? 0.8 : 0.2
            colors[i].withAlphaComponent(alpha).setFill()
            let size: CGFloat = (i == visible) ? 2.0 : 1.2
            NSBezierPath(ovalIn: NSRect(
                x: positions[i].0, y: positions[i].1,
                width: size, height: size
            )).fill()
        }
    }

    // MARK: - Pug Running

    private func drawPugRunning(at o: NSPoint, frame: Int) {
        let tan = NSColor(calibratedRed: 0.82, green: 0.72, blue: 0.55, alpha: 1.0)
        let dark = NSColor(calibratedRed: 0.35, green: 0.25, blue: 0.18, alpha: 1.0)
        let bounce: CGFloat = microBounce ? 1 : 0

        // Tail (wagging fast)
        dark.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 1.5
        tail.lineCapStyle = .round
        let tailSwing: CGFloat = tailWagPhase ? 2 : -1
        tail.move(to: NSPoint(x: o.x + 1, y: o.y + 5 + bounce))
        tail.curve(to: NSPoint(x: o.x - 1 + tailSwing, y: o.y + 11 + bounce),
                   controlPoint1: NSPoint(x: o.x - 2, y: o.y + 6 + bounce),
                   controlPoint2: NSPoint(x: o.x - 2 + tailSwing, y: o.y + 10 + bounce))
        tail.stroke()

        // Legs — running animation
        switch frame {
        case 0:
            leg(x: o.x + 2, y: o.y - 3, color: tan)
            leg(x: o.x + 10, y: o.y - 3, color: tan)
        default:
            leg(x: o.x + 4, y: o.y - 3, color: tan)
            leg(x: o.x + 7, y: o.y - 3, color: tan)
        }

        drawPugBody(at: NSPoint(x: o.x, y: o.y + bounce), tan: tan, dark: dark)

        // Open mouth (panting) with tongue that flickers
        NSColor.systemPink.setFill()
        let tongueSize: CGFloat = tongueFlicker ? 2.0 : 1.5
        NSBezierPath(ovalIn: NSRect(x: o.x + 14, y: o.y + 2 + bounce, width: tongueSize, height: tongueSize)).fill()

        // Sweat drop when running hard
        if frame == 1 {
            NSColor.systemCyan.withAlphaComponent(0.4).setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 10, y: o.y + 10 + bounce, width: 1.2, height: 1.5)).fill()
        }

        // Dust (more particles when running)
        NSColor.gray.withAlphaComponent(0.35).setFill()
        if frame == 0 {
            NSBezierPath(ovalIn: NSRect(x: o.x - 1, y: o.y - 1, width: 2, height: 2)).fill()
            NSBezierPath(ovalIn: NSRect(x: o.x - 3, y: o.y + 1, width: 1.5, height: 1.5)).fill()
            NSBezierPath(ovalIn: NSRect(x: o.x - 4, y: o.y - 0.5, width: 1, height: 1)).fill()
        } else {
            NSBezierPath(ovalIn: NSRect(x: o.x, y: o.y, width: 2, height: 2)).fill()
            NSBezierPath(ovalIn: NSRect(x: o.x - 2, y: o.y - 1, width: 1.5, height: 1.5)).fill()
            NSBezierPath(ovalIn: NSRect(x: o.x - 3, y: o.y + 0.5, width: 1, height: 1)).fill()
        }
    }

    // MARK: - Pug Idle Activities

    private func drawPugIdle(at o: NSPoint, activity: Int) {
        let tan = NSColor(calibratedRed: 0.82, green: 0.72, blue: 0.55, alpha: 1.0)
        let dark = NSColor(calibratedRed: 0.35, green: 0.25, blue: 0.18, alpha: 1.0)

        switch activity {
        case 0: drawPugStanding(at: o, tan: tan, dark: dark)
        case 1: drawPugSitting(at: o, tan: tan, dark: dark)
        case 2: drawPugLookingUp(at: o, tan: tan, dark: dark)
        case 3: drawPugTailWag(at: o, tan: tan, dark: dark)
        case 4: drawPugScratching(at: o, tan: tan, dark: dark)
        case 5: drawPugSleeping(at: o, tan: tan, dark: dark)
        case 6: drawPugStretching(at: o, tan: tan, dark: dark)
        case 7: drawPugPlayBow(at: o, tan: tan, dark: dark)
        default: drawPugStanding(at: o, tan: tan, dark: dark)
        }
    }

    private func drawPugStanding(at o: NSPoint, tan: NSColor, dark: NSColor) {
        dark.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 1.5
        tail.lineCapStyle = .round
        let tw: CGFloat = tailWagPhase ? 1 : -1
        tail.move(to: NSPoint(x: o.x + 1, y: o.y + 5))
        tail.curve(to: NSPoint(x: o.x - 1 + tw, y: o.y + 11),
                   controlPoint1: NSPoint(x: o.x - 2, y: o.y + 6),
                   controlPoint2: NSPoint(x: o.x - 2 + tw, y: o.y + 10))
        tail.stroke()

        leg(x: o.x + 3, y: o.y - 2, color: tan)
        leg(x: o.x + 9, y: o.y - 2, color: tan)
        drawPugBody(at: o, tan: tan, dark: dark)
    }

    private func drawPugSitting(at o: NSPoint, tan: NSColor, dark: NSColor) {
        dark.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 1.5; tail.lineCapStyle = .round
        tail.move(to: NSPoint(x: o.x + 1, y: o.y + 3))
        tail.curve(to: NSPoint(x: o.x - 2, y: o.y + 8),
                   controlPoint1: NSPoint(x: o.x - 2, y: o.y + 4),
                   controlPoint2: NSPoint(x: o.x - 3, y: o.y + 7))
        tail.stroke()

        tan.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 0, width: 11, height: 6)).fill()
        leg(x: o.x + 3, y: o.y - 1, color: tan)
        leg(x: o.x + 8, y: o.y - 1, color: tan)

        let head = NSBezierPath(ovalIn: NSRect(x: o.x + 7, y: o.y + 1, width: 8, height: 7))
        head.fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 8, y: o.y + 7, width: 3, height: 2.5)).fill()

        if eyesClosed {
            dark.setStroke()
            let blink = NSBezierPath(); blink.lineWidth = 1.0
            blink.move(to: NSPoint(x: o.x + 11, y: o.y + 5))
            blink.line(to: NSPoint(x: o.x + 13, y: o.y + 5))
            blink.stroke()
        } else {
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 11, y: o.y + 4.5, width: 2.5, height: 2)).fill()
            dark.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 11.5, y: o.y + 4.5, width: 1.5, height: 1.2)).fill()
        }

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 13.5, y: o.y + 2.5, width: 2, height: 1.5)).fill()
    }

    private func drawPugLookingUp(at o: NSPoint, tan: NSColor, dark: NSColor) {
        dark.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 1.5; tail.lineCapStyle = .round
        tail.move(to: NSPoint(x: o.x + 1, y: o.y + 5))
        tail.curve(to: NSPoint(x: o.x - 1, y: o.y + 11),
                   controlPoint1: NSPoint(x: o.x - 2, y: o.y + 6),
                   controlPoint2: NSPoint(x: o.x - 2, y: o.y + 10))
        tail.stroke()

        leg(x: o.x + 3, y: o.y - 2, color: tan)
        leg(x: o.x + 9, y: o.y - 2, color: tan)

        tan.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 1, width: 10, height: 7)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 7, y: o.y + 4, width: 8, height: 7)).fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 8, y: o.y + 10, width: 3, height: 2.5)).fill()

        if eyesClosed {
            dark.setStroke()
            let blink = NSBezierPath(); blink.lineWidth = 1.0
            blink.move(to: NSPoint(x: o.x + 11, y: o.y + 8.5))
            blink.line(to: NSPoint(x: o.x + 13, y: o.y + 8.5))
            blink.stroke()
        } else {
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 11, y: o.y + 7.5, width: 2.5, height: 2.5)).fill()
            dark.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 11.5, y: o.y + 8.5, width: 1.5, height: 1.5)).fill()
        }

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 13.5, y: o.y + 6, width: 2, height: 1.5)).fill()

        NSColor.systemYellow.withAlphaComponent(0.7).setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 10, y: o.y + 14, width: 2, height: 2)).fill()
    }

    private func drawPugTailWag(at o: NSPoint, tan: NSColor, dark: NSColor) {
        dark.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 1.5; tail.lineCapStyle = .round
        let tw: CGFloat = tailWagPhase ? 3 : -1
        tail.move(to: NSPoint(x: o.x + 1, y: o.y + 5))
        tail.curve(to: NSPoint(x: o.x + tw, y: o.y + 12),
                   controlPoint1: NSPoint(x: o.x - 1, y: o.y + 7),
                   controlPoint2: NSPoint(x: o.x + tw - 1, y: o.y + 10))
        tail.stroke()

        NSColor.gray.withAlphaComponent(0.3).setStroke()
        let motion = NSBezierPath(); motion.lineWidth = 0.5
        motion.move(to: NSPoint(x: o.x - 2, y: o.y + 10))
        motion.line(to: NSPoint(x: o.x - 4, y: o.y + 10))
        motion.move(to: NSPoint(x: o.x - 1, y: o.y + 12))
        motion.line(to: NSPoint(x: o.x - 3, y: o.y + 12))
        motion.stroke()

        leg(x: o.x + 3, y: o.y - 2, color: tan)
        leg(x: o.x + 9, y: o.y - 2, color: tan)
        drawPugBody(at: o, tan: tan, dark: dark)
    }

    private func drawPugScratching(at o: NSPoint, tan: NSColor, dark: NSColor) {
        dark.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 1.5; tail.lineCapStyle = .round
        tail.move(to: NSPoint(x: o.x + 1, y: o.y + 5))
        tail.curve(to: NSPoint(x: o.x - 1, y: o.y + 11),
                   controlPoint1: NSPoint(x: o.x - 2, y: o.y + 6),
                   controlPoint2: NSPoint(x: o.x - 2, y: o.y + 10))
        tail.stroke()

        leg(x: o.x + 3, y: o.y - 2, color: tan)
        tan.setFill()
        NSBezierPath(roundedRect: NSRect(x: o.x + 9, y: o.y + 4, width: 2.5, height: 4),
                     xRadius: 1, yRadius: 1).fill()

        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 1, width: 10, height: 7)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 7, y: o.y + 2, width: 8, height: 7)).fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 9, y: o.y + 8, width: 3, height: 2)).fill()

        if eyesClosed {
            dark.setStroke()
            let blink = NSBezierPath(); blink.lineWidth = 1.0
            blink.move(to: NSPoint(x: o.x + 11, y: o.y + 6))
            blink.line(to: NSPoint(x: o.x + 13, y: o.y + 6))
            blink.stroke()
        } else {
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 11, y: o.y + 5.5, width: 2.5, height: 1.5)).fill()
            dark.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 11.5, y: o.y + 5.5, width: 1.5, height: 1)).fill()
        }

        // Scratch motion lines
        NSColor.gray.withAlphaComponent(0.3).setStroke()
        let scratch = NSBezierPath(); scratch.lineWidth = 0.5
        scratch.move(to: NSPoint(x: o.x + 10, y: o.y + 8.5))
        scratch.line(to: NSPoint(x: o.x + 11, y: o.y + 9.5))
        scratch.move(to: NSPoint(x: o.x + 11, y: o.y + 8))
        scratch.line(to: NSPoint(x: o.x + 12, y: o.y + 9))
        scratch.stroke()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 13.5, y: o.y + 3.5, width: 2, height: 1.5)).fill()
    }

    private func drawPugSleeping(at o: NSPoint, tan: NSColor, dark: NSColor) {
        tan.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 0, y: o.y + 0, width: 12, height: 5)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 8, y: o.y + 0, width: 7, height: 6)).fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 9, y: o.y + 5, width: 3, height: 2)).fill()

        dark.setStroke()
        let eye = NSBezierPath(); eye.lineWidth = 0.8
        eye.move(to: NSPoint(x: o.x + 11, y: o.y + 3.5))
        eye.line(to: NSPoint(x: o.x + 13, y: o.y + 3.5))
        eye.stroke()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 13.5, y: o.y + 1.5, width: 1.5, height: 1.2)).fill()

        leg(x: o.x + 0, y: o.y - 1, color: tan)

        // Breathing animation (body slightly rises)
        let breathOff: CGFloat = tailWagPhase ? 0.5 : 0

        // ZZZ (cycling position)
        let font = NSFont.systemFont(ofSize: 5, weight: .bold)
        let str = NSAttributedString(string: "z", attributes: [.font: font, .foregroundColor: NSColor.gray.withAlphaComponent(0.4)])
        str.draw(at: NSPoint(x: o.x + 12, y: o.y + 8 + breathOff))
        let str2 = NSAttributedString(string: "Z", attributes: [.font: NSFont.systemFont(ofSize: 6, weight: .bold), .foregroundColor: NSColor.gray.withAlphaComponent(0.3)])
        str2.draw(at: NSPoint(x: o.x + 14, y: o.y + 11 + breathOff))
    }

    // NEW: Stretching pose
    private func drawPugStretching(at o: NSPoint, tan: NSColor, dark: NSColor) {
        // Body elongated, front down, butt up
        dark.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 1.5; tail.lineCapStyle = .round
        tail.move(to: NSPoint(x: o.x + 1, y: o.y + 7))
        tail.curve(to: NSPoint(x: o.x + 0, y: o.y + 13),
                   controlPoint1: NSPoint(x: o.x - 1, y: o.y + 9),
                   controlPoint2: NSPoint(x: o.x + 1, y: o.y + 12))
        tail.stroke()

        // Back legs (standing tall)
        leg(x: o.x + 2, y: o.y - 1, color: tan)
        leg(x: o.x + 5, y: o.y - 1, color: tan)

        // Front paws (stretched forward, flat)
        tan.setFill()
        NSBezierPath(roundedRect: NSRect(x: o.x + 10, y: o.y - 2, width: 5, height: 2),
                     xRadius: 1, yRadius: 1).fill()

        // Body (angled — butt up, front down)
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 2, width: 10, height: 7)).fill()

        // Head (low)
        NSBezierPath(ovalIn: NSRect(x: o.x + 9, y: o.y - 1, width: 7, height: 6)).fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 10, y: o.y + 4, width: 3, height: 2)).fill()

        // Eyes (happy squint)
        dark.setStroke()
        let eye = NSBezierPath(); eye.lineWidth = 0.8
        eye.move(to: NSPoint(x: o.x + 12, y: o.y + 2))
        eye.line(to: NSPoint(x: o.x + 14, y: o.y + 2))
        eye.stroke()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 14, y: o.y + 0, width: 1.5, height: 1.2)).fill()

        // Yawn bubble
        let font = NSFont.systemFont(ofSize: 5, weight: .bold)
        let str = NSAttributedString(string: "~", attributes: [.font: font, .foregroundColor: NSColor.gray.withAlphaComponent(0.3)])
        str.draw(at: NSPoint(x: o.x + 15, y: o.y + 3))
    }

    // NEW: Play bow pose (front down, tail up, excited)
    private func drawPugPlayBow(at o: NSPoint, tan: NSColor, dark: NSColor) {
        // Tail up and wagging
        dark.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 1.5; tail.lineCapStyle = .round
        let tw: CGFloat = tailWagPhase ? 2 : -1
        tail.move(to: NSPoint(x: o.x + 2, y: o.y + 6))
        tail.curve(to: NSPoint(x: o.x + tw, y: o.y + 13),
                   controlPoint1: NSPoint(x: o.x - 1, y: o.y + 8),
                   controlPoint2: NSPoint(x: o.x + tw, y: o.y + 11))
        tail.stroke()

        // Back legs (standing)
        leg(x: o.x + 2, y: o.y - 1, color: tan)
        leg(x: o.x + 5, y: o.y - 1, color: tan)

        // Front paws (down)
        leg(x: o.x + 10, y: o.y - 3, color: tan)
        leg(x: o.x + 13, y: o.y - 3, color: tan)

        // Body (angled)
        tan.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 1, width: 12, height: 7)).fill()

        // Head (low, looking forward eagerly)
        NSBezierPath(ovalIn: NSRect(x: o.x + 10, y: o.y - 2, width: 7, height: 6)).fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 11, y: o.y + 3, width: 3, height: 2)).fill()

        // Big eager eyes
        if eyesClosed {
            dark.setStroke()
            let blink = NSBezierPath(); blink.lineWidth = 1.0
            blink.move(to: NSPoint(x: o.x + 13, y: o.y + 1.5))
            blink.line(to: NSPoint(x: o.x + 15, y: o.y + 1.5))
            blink.stroke()
        } else {
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 13, y: o.y + 0.5, width: 2.5, height: 2.5)).fill()
            dark.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 13.5, y: o.y + 1, width: 1.5, height: 1.5)).fill()
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 14, y: o.y + 1.8, width: 0.6, height: 0.6)).fill()
        }

        // Nose
        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 15.5, y: o.y - 0.5, width: 1.5, height: 1.2)).fill()

        // Tongue out (excited)
        NSColor.systemPink.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 15, y: o.y - 2, width: 1.5, height: 1.5)).fill()

        // Excitement mark
        NSColor.systemYellow.withAlphaComponent(0.5).setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 14, y: o.y + 5, width: 1.5, height: 1.5)).fill()
    }

    // MARK: - Pug Body Helper

    private func drawPugBody(at o: NSPoint, tan: NSColor, dark: NSColor) {
        tan.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 1, width: 10, height: 7)).fill()

        let head = NSBezierPath(ovalIn: NSRect(x: o.x + 7, y: o.y + 2, width: 8, height: 7))
        head.fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 8, y: o.y + 8, width: 3, height: 2.5)).fill()

        if eyesClosed {
            dark.setStroke()
            let blink = NSBezierPath(); blink.lineWidth = 1.0
            blink.move(to: NSPoint(x: o.x + 11, y: o.y + 6.5))
            blink.line(to: NSPoint(x: o.x + 13, y: o.y + 6.5))
            blink.stroke()
        } else {
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 11, y: o.y + 5.5, width: 2.5, height: 2.5)).fill()
            dark.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 11.5, y: o.y + 6, width: 1.5, height: 1.5)).fill()
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 12, y: o.y + 7, width: 0.8, height: 0.8)).fill()
        }

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 13.5, y: o.y + 3.5, width: 2, height: 1.5)).fill()
    }

    // MARK: - Raccoon Running

    private func drawRaccoonRunning(at o: NSPoint, frame: Int) {
        let gray = NSColor(calibratedRed: 0.55, green: 0.55, blue: 0.58, alpha: 1.0)
        let dark = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.22, alpha: 1.0)
        let bounce: CGFloat = microBounce ? 1 : 0

        drawRaccoonTail(at: NSPoint(x: o.x, y: o.y + bounce), gray: gray, dark: dark, wag: tailWagPhase)

        switch frame {
        case 0:
            leg(x: o.x + 2, y: o.y - 3, color: gray)
            leg(x: o.x + 10, y: o.y - 3, color: gray)
        default:
            leg(x: o.x + 4, y: o.y - 3, color: gray)
            leg(x: o.x + 7, y: o.y - 3, color: gray)
        }

        drawRaccoonBody(at: NSPoint(x: o.x, y: o.y + bounce), gray: gray, dark: dark)

        // Sweat drop
        if frame == 0 {
            NSColor.systemCyan.withAlphaComponent(0.35).setFill()
            NSBezierPath(ovalIn: NSRect(x: o.x + 9, y: o.y + 10 + bounce, width: 1, height: 1.3)).fill()
        }

        // Dust
        NSColor.gray.withAlphaComponent(0.35).setFill()
        if frame == 0 {
            NSBezierPath(ovalIn: NSRect(x: o.x - 1, y: o.y - 1, width: 2, height: 2)).fill()
            NSBezierPath(ovalIn: NSRect(x: o.x - 3, y: o.y + 1, width: 1.5, height: 1.5)).fill()
            NSBezierPath(ovalIn: NSRect(x: o.x - 4, y: o.y - 0.5, width: 1, height: 1)).fill()
        } else {
            NSBezierPath(ovalIn: NSRect(x: o.x, y: o.y, width: 2, height: 2)).fill()
            NSBezierPath(ovalIn: NSRect(x: o.x - 2, y: o.y - 1, width: 1.5, height: 1.5)).fill()
            NSBezierPath(ovalIn: NSRect(x: o.x - 3, y: o.y + 0.5, width: 1, height: 1)).fill()
        }
    }

    // MARK: - Raccoon Idle Activities

    private func drawRaccoonIdle(at o: NSPoint, activity: Int) {
        let gray = NSColor(calibratedRed: 0.55, green: 0.55, blue: 0.58, alpha: 1.0)
        let dark = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.22, alpha: 1.0)

        switch activity {
        case 0: drawRaccoonStanding(at: o, gray: gray, dark: dark)
        case 1: drawRaccoonSitting(at: o, gray: gray, dark: dark)
        case 2: drawRaccoonSniffing(at: o, gray: gray, dark: dark)
        case 3: drawRaccoonTailWag(at: o, gray: gray, dark: dark)
        case 4: drawRaccoonWashing(at: o, gray: gray, dark: dark)
        case 5: drawRaccoonSleeping(at: o, gray: gray, dark: dark)
        case 6: drawRaccoonStretching(at: o, gray: gray, dark: dark)
        case 7: drawRaccoonPouncing(at: o, gray: gray, dark: dark)
        default: drawRaccoonStanding(at: o, gray: gray, dark: dark)
        }
    }

    private func drawRaccoonStanding(at o: NSPoint, gray: NSColor, dark: NSColor) {
        drawRaccoonTail(at: o, gray: gray, dark: dark, wag: tailWagPhase)
        leg(x: o.x + 3, y: o.y - 2, color: gray)
        leg(x: o.x + 9, y: o.y - 2, color: gray)
        drawRaccoonBody(at: o, gray: gray, dark: dark)
    }

    private func drawRaccoonSitting(at o: NSPoint, gray: NSColor, dark: NSColor) {
        drawRaccoonTail(at: o, gray: gray, dark: dark, wag: false)
        gray.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 0, width: 11, height: 5)).fill()
        leg(x: o.x + 3, y: o.y - 1, color: gray)
        leg(x: o.x + 8, y: o.y - 1, color: gray)
        NSBezierPath(ovalIn: NSRect(x: o.x + 7, y: o.y + 1, width: 8, height: 7)).fill()
        drawRaccoonFace(at: NSPoint(x: o.x, y: o.y - 1), dark: dark, eyeStyle: .halfClosed)
    }

    private func drawRaccoonSniffing(at o: NSPoint, gray: NSColor, dark: NSColor) {
        drawRaccoonTail(at: o, gray: gray, dark: dark, wag: false)
        leg(x: o.x + 3, y: o.y - 2, color: gray)
        leg(x: o.x + 9, y: o.y - 2, color: gray)
        gray.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 1, width: 10, height: 7)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 8, y: o.y + 1, width: 8, height: 7)).fill()
        drawRaccoonFace(at: o, dark: dark, eyeStyle: .normal)

        NSColor.gray.withAlphaComponent(0.3).setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 15.5, y: o.y + 4, width: 1.5, height: 1.5)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 16.5, y: o.y + 5.5, width: 1, height: 1)).fill()
    }

    private func drawRaccoonTailWag(at o: NSPoint, gray: NSColor, dark: NSColor) {
        drawRaccoonTail(at: o, gray: gray, dark: dark, wag: true)

        NSColor.gray.withAlphaComponent(0.3).setStroke()
        let motion = NSBezierPath(); motion.lineWidth = 0.5
        motion.move(to: NSPoint(x: o.x - 3, y: o.y + 10))
        motion.line(to: NSPoint(x: o.x - 5, y: o.y + 10))
        motion.move(to: NSPoint(x: o.x - 2, y: o.y + 12))
        motion.line(to: NSPoint(x: o.x - 4, y: o.y + 12))
        motion.stroke()

        leg(x: o.x + 3, y: o.y - 2, color: gray)
        leg(x: o.x + 9, y: o.y - 2, color: gray)
        drawRaccoonBody(at: o, gray: gray, dark: dark)
    }

    private func drawRaccoonWashing(at o: NSPoint, gray: NSColor, dark: NSColor) {
        drawRaccoonTail(at: o, gray: gray, dark: dark, wag: false)
        leg(x: o.x + 3, y: o.y - 2, color: gray)

        gray.setFill()
        NSBezierPath(roundedRect: NSRect(x: o.x + 10, y: o.y + 3, width: 2.5, height: 4),
                     xRadius: 1, yRadius: 1).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 1, width: 10, height: 7)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 7, y: o.y + 2, width: 8, height: 7)).fill()
        drawRaccoonFace(at: o, dark: dark, eyeStyle: .squinting)

        NSColor.systemCyan.withAlphaComponent(0.4).setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 12, y: o.y + 2, width: 1.2, height: 1.5)).fill()
    }

    private func drawRaccoonSleeping(at o: NSPoint, gray: NSColor, dark: NSColor) {
        gray.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 0, y: o.y + 0, width: 12, height: 5)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 8, y: o.y + 0, width: 7, height: 6)).fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 9.5, y: o.y + 2.5, width: 3, height: 2.5)).fill()

        dark.setStroke()
        let eye = NSBezierPath(); eye.lineWidth = 0.8
        eye.move(to: NSPoint(x: o.x + 10, y: o.y + 3.5))
        eye.line(to: NSPoint(x: o.x + 12, y: o.y + 3.5))
        eye.stroke()

        let earPath = NSBezierPath()
        dark.setFill()
        earPath.move(to: NSPoint(x: o.x + 9, y: o.y + 5))
        earPath.line(to: NSPoint(x: o.x + 10, y: o.y + 7.5))
        earPath.line(to: NSPoint(x: o.x + 11, y: o.y + 5.5))
        earPath.close()
        earPath.fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 13, y: o.y + 1.5, width: 1.5, height: 1.2)).fill()

        drawRaccoonTail(at: NSPoint(x: o.x, y: o.y - 2), gray: gray, dark: dark, wag: false)

        let breathOff: CGFloat = tailWagPhase ? 0.5 : 0
        let font = NSFont.systemFont(ofSize: 5, weight: .bold)
        let str = NSAttributedString(string: "z", attributes: [.font: font, .foregroundColor: NSColor.gray.withAlphaComponent(0.4)])
        str.draw(at: NSPoint(x: o.x + 12, y: o.y + 8 + breathOff))
        let str2 = NSAttributedString(string: "Z", attributes: [.font: NSFont.systemFont(ofSize: 6, weight: .bold), .foregroundColor: NSColor.gray.withAlphaComponent(0.3)])
        str2.draw(at: NSPoint(x: o.x + 14, y: o.y + 11 + breathOff))
    }

    // NEW: Raccoon stretching
    private func drawRaccoonStretching(at o: NSPoint, gray: NSColor, dark: NSColor) {
        drawRaccoonTail(at: NSPoint(x: o.x, y: o.y + 2), gray: gray, dark: dark, wag: false)

        leg(x: o.x + 2, y: o.y - 1, color: gray)
        leg(x: o.x + 5, y: o.y - 1, color: gray)

        gray.setFill()
        NSBezierPath(roundedRect: NSRect(x: o.x + 10, y: o.y - 2, width: 5, height: 2),
                     xRadius: 1, yRadius: 1).fill()

        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 2, width: 10, height: 7)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 9, y: o.y - 1, width: 7, height: 6)).fill()

        drawRaccoonFace(at: NSPoint(x: o.x, y: o.y - 3), dark: dark, eyeStyle: .squinting)

        let font = NSFont.systemFont(ofSize: 5, weight: .bold)
        let str = NSAttributedString(string: "~", attributes: [.font: font, .foregroundColor: NSColor.gray.withAlphaComponent(0.3)])
        str.draw(at: NSPoint(x: o.x + 15, y: o.y + 0))
    }

    // NEW: Raccoon pouncing (playful crouch)
    private func drawRaccoonPouncing(at o: NSPoint, gray: NSColor, dark: NSColor) {
        drawRaccoonTail(at: NSPoint(x: o.x, y: o.y), gray: gray, dark: dark, wag: tailWagPhase)

        // Crouching legs
        leg(x: o.x + 2, y: o.y - 1, color: gray)
        leg(x: o.x + 4, y: o.y - 1, color: gray)
        leg(x: o.x + 10, y: o.y - 2, color: gray)
        leg(x: o.x + 12, y: o.y - 2, color: gray)

        gray.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 0, width: 12, height: 6)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 9, y: o.y - 1, width: 7, height: 6)).fill()

        drawRaccoonFace(at: NSPoint(x: o.x, y: o.y - 2), dark: dark, eyeStyle: .normal)

        // Wiggling butt indicator
        NSColor.gray.withAlphaComponent(0.25).setStroke()
        let wiggle = NSBezierPath(); wiggle.lineWidth = 0.5
        let tw: CGFloat = tailWagPhase ? 1 : -1
        wiggle.move(to: NSPoint(x: o.x - 1, y: o.y + 3 + tw))
        wiggle.line(to: NSPoint(x: o.x - 3, y: o.y + 3 - tw))
        wiggle.stroke()

        // Excited eyes
        NSColor.systemYellow.withAlphaComponent(0.4).setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 13, y: o.y + 4, width: 1.5, height: 1.5)).fill()
    }

    // MARK: - Raccoon Helpers

    private enum EyeStyle { case normal, halfClosed, squinting }

    private func drawRaccoonBody(at o: NSPoint, gray: NSColor, dark: NSColor) {
        gray.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 1, y: o.y + 1, width: 10, height: 7)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 7, y: o.y + 2, width: 8, height: 7)).fill()
        drawRaccoonFace(at: o, dark: dark, eyeStyle: .normal)
    }

    private func drawRaccoonFace(at o: NSPoint, dark: NSColor, eyeStyle: EyeStyle) {
        let light = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.82, alpha: 1.0)

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 9.5, y: o.y + 4.5, width: 3, height: 3)).fill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 12, y: o.y + 4.5, width: 2.5, height: 2.5)).fill()

        light.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 10.5, y: o.y + 3, width: 3, height: 2)).fill()

        if eyesClosed {
            dark.setStroke()
            let blink = NSBezierPath(); blink.lineWidth = 0.8
            blink.move(to: NSPoint(x: o.x + 10, y: o.y + 6))
            blink.line(to: NSPoint(x: o.x + 12.5, y: o.y + 6))
            blink.stroke()
        } else {
            switch eyeStyle {
            case .normal:
                NSColor.white.setFill()
                NSBezierPath(ovalIn: NSRect(x: o.x + 10, y: o.y + 5.5, width: 2.5, height: 2.5)).fill()
                dark.setFill()
                NSBezierPath(ovalIn: NSRect(x: o.x + 10.5, y: o.y + 6, width: 1.5, height: 1.5)).fill()
                NSColor.white.setFill()
                NSBezierPath(ovalIn: NSRect(x: o.x + 11, y: o.y + 6.8, width: 0.6, height: 0.6)).fill()
            case .halfClosed:
                NSColor.white.setFill()
                NSBezierPath(ovalIn: NSRect(x: o.x + 10, y: o.y + 5.5, width: 2.5, height: 1.5)).fill()
                dark.setFill()
                NSBezierPath(ovalIn: NSRect(x: o.x + 10.5, y: o.y + 5.5, width: 1.5, height: 1)).fill()
            case .squinting:
                dark.setStroke()
                let eye = NSBezierPath(); eye.lineWidth = 0.8
                eye.move(to: NSPoint(x: o.x + 10, y: o.y + 6))
                eye.line(to: NSPoint(x: o.x + 12.5, y: o.y + 6))
                eye.stroke()
            }
        }

        dark.setFill()
        let earPath = NSBezierPath()
        earPath.move(to: NSPoint(x: o.x + 8, y: o.y + 8))
        earPath.line(to: NSPoint(x: o.x + 9.5, y: o.y + 11))
        earPath.line(to: NSPoint(x: o.x + 11, y: o.y + 8.5))
        earPath.close()
        earPath.fill()

        dark.setFill()
        NSBezierPath(ovalIn: NSRect(x: o.x + 13.5, y: o.y + 3.5, width: 1.5, height: 1.2)).fill()

        NSColor.gray.withAlphaComponent(0.25).setStroke()
        let w = NSBezierPath(); w.lineWidth = 0.5
        w.move(to: NSPoint(x: o.x + 14, y: o.y + 4.5))
        w.line(to: NSPoint(x: o.x + 16, y: o.y + 5))
        w.move(to: NSPoint(x: o.x + 14, y: o.y + 3.5))
        w.line(to: NSPoint(x: o.x + 16, y: o.y + 3))
        w.stroke()
    }

    private func drawRaccoonTail(at o: NSPoint, gray: NSColor, dark: NSColor, wag: Bool) {
        gray.setStroke()
        let tail = NSBezierPath()
        tail.lineWidth = 2.5; tail.lineCapStyle = .round
        let yOff: CGFloat = wag ? 1 : 0
        tail.move(to: NSPoint(x: o.x + 1, y: o.y + 5))
        tail.curve(to: NSPoint(x: o.x - 2, y: o.y + 12 + yOff),
                   controlPoint1: NSPoint(x: o.x - 3, y: o.y + 7),
                   controlPoint2: NSPoint(x: o.x - 3, y: o.y + 11 + yOff))
        tail.stroke()

        dark.setStroke()
        let s1 = NSBezierPath(); s1.lineWidth = 2.5; s1.lineCapStyle = .round
        s1.move(to: NSPoint(x: o.x + 0.5, y: o.y + 5.5))
        s1.line(to: NSPoint(x: o.x - 0.5, y: o.y + 7))
        s1.stroke()
        let s2 = NSBezierPath(); s2.lineWidth = 2.5; s2.lineCapStyle = .round
        s2.move(to: NSPoint(x: o.x - 1.5, y: o.y + 8.5))
        s2.line(to: NSPoint(x: o.x - 2.5, y: o.y + 10))
        s2.stroke()
    }

    // MARK: - Accessory

    private func drawAccessory(at o: NSPoint, tier: PetEvolutionTier) {
        switch tier {
        case .base: break
        case .bandana:
            NSColor.systemRed.setFill()
            let path = NSBezierPath()
            path.move(to: NSPoint(x: o.x + 7, y: o.y + 2))
            path.line(to: NSPoint(x: o.x + 10, y: o.y + 2))
            path.line(to: NSPoint(x: o.x + 8.5, y: o.y - 0.5))
            path.close()
            path.fill()
        case .backpack:
            NSColor.systemBrown.setFill()
            NSBezierPath(roundedRect: NSRect(x: o.x + 3, y: o.y + 6, width: 4, height: 3),
                         xRadius: 0.5, yRadius: 0.5).fill()
        case .cape:
            NSColor.systemPurple.withAlphaComponent(0.8).setFill()
            let path = NSBezierPath()
            path.move(to: NSPoint(x: o.x + 3, y: o.y + 7))
            path.line(to: NSPoint(x: o.x - 2, y: o.y + 9))
            path.line(to: NSPoint(x: o.x - 1, y: o.y + 4))
            path.line(to: NSPoint(x: o.x + 3, y: o.y + 3))
            path.close()
            path.fill()
        case .crown:
            NSColor.systemYellow.setFill()
            let path = NSBezierPath()
            path.move(to: NSPoint(x: o.x + 8, y: o.y + 10))
            path.line(to: NSPoint(x: o.x + 9, y: o.y + 13))
            path.line(to: NSPoint(x: o.x + 10.5, y: o.y + 11))
            path.line(to: NSPoint(x: o.x + 12, y: o.y + 13))
            path.line(to: NSPoint(x: o.x + 13, y: o.y + 10))
            path.close()
            path.fill()
        }
    }

    // MARK: - Helpers

    private func leg(x: CGFloat, y: CGFloat, color: NSColor) {
        let rect = NSRect(x: x, y: y, width: 2.5, height: 5)
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
    }

    private var barFillColor: NSColor {
        if progress >= 1.0 { return .systemGreen }
        if progress >= 0.5 { return .systemGreen }
        if progress >= 0.25 { return .systemOrange }
        return .systemBlue
    }
}
