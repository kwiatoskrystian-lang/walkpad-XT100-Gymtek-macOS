import SwiftUI

struct ConnectionStatusPill: View {
    let state: ConnectionState
    let deviceName: String?

    @State private var isPulsing = false
    @State private var connectedGlow = false
    @State private var scanRotation: Double = 0
    @State private var dotScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                // Outer glow ring for connected/active
                if state == .connected || state == .workoutActive {
                    Circle()
                        .stroke(pillColor.opacity(connectedGlow ? 0.5 : 0.1), lineWidth: 2)
                        .frame(width: 12, height: 12)
                        .scaleEffect(connectedGlow ? 1.3 : 0.9)
                }

                // Scanning ring
                if state == .scanning || state == .connecting {
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(pillColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(scanRotation))
                }

                Circle()
                    .fill(pillColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .scaleEffect(dotScale)
            }
            .frame(width: 14, height: 14)

            Text(displayText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(pillColor.opacity(0.15), in: Capsule())
        .overlay(Capsule().stroke(pillColor.opacity(0.3), lineWidth: 1))
        .onAppear { startAnimations() }
        .onChange(of: state) { old, new in
            startAnimations()
            // Bounce dot on state change
            if old != new {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    dotScale = 1.4
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        dotScale = 1.0
                    }
                }
            }
        }
    }

    private var displayText: String {
        if state.isConnected, let name = deviceName {
            return "\(state.label) — \(name)"
        }
        return state.label
    }

    private var pillColor: Color {
        switch state {
        case .disconnected: .red
        case .scanning, .connecting: .orange
        case .connected, .workoutActive: .green
        }
    }

    private func startAnimations() {
        isPulsing = false
        connectedGlow = false
        scanRotation = 0

        if state == .scanning || state == .connecting {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                scanRotation = 360
            }
        } else if state == .connected || state == .workoutActive {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                connectedGlow = true
            }
        }
    }
}
