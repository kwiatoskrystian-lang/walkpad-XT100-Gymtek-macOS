import AppKit

enum SoundEffect {
    case goalAchieved
    case achievementUnlocked
    case streakMilestone
    case shieldEarned
    case workoutStarted
    case workoutEnded

    var systemSoundName: NSSound.Name {
        switch self {
        case .goalAchieved:        return "Glass"
        case .achievementUnlocked: return "Hero"
        case .streakMilestone:     return "Purr"
        case .shieldEarned:        return "Submarine"
        case .workoutStarted:      return "Tink"
        case .workoutEnded:        return "Blow"
        }
    }
}

final class SoundManager {
    static let shared = SoundManager()

    private var enabled: Bool { AppSettings.shared.notificationsEnabled }

    private init() {}

    func play(_ effect: SoundEffect) {
        guard enabled else { return }
        NSSound(named: effect.systemSoundName)?.play()
    }
}
