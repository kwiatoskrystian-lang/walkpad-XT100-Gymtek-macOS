import SwiftUI

/// Static gradient tint based on time of day. No animations — safe for MenuBarExtra windows.
struct TimeOfDayTint: View {
    private var hour: Int {
        Calendar.current.component(.hour, from: .now)
    }

    private var colors: [Color] {
        switch hour {
        case 6..<12:
            // Morning — warm gold
            [Color(red: 1.0, green: 0.95, blue: 0.85).opacity(0.2),
             Color(red: 0.95, green: 0.88, blue: 0.75).opacity(0.08)]
        case 12..<18:
            // Afternoon — cool blue
            [Color(red: 0.85, green: 0.93, blue: 1.0).opacity(0.15),
             Color(red: 0.9, green: 0.95, blue: 1.0).opacity(0.05)]
        case 18..<22:
            // Evening — sunset
            [Color(red: 1.0, green: 0.7, blue: 0.5).opacity(0.12),
             Color(red: 0.6, green: 0.4, blue: 0.7).opacity(0.08)]
        default:
            // Night — dark blue
            [Color(red: 0.15, green: 0.15, blue: 0.3).opacity(0.15),
             Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.1)]
        }
    }

    var body: some View {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}
