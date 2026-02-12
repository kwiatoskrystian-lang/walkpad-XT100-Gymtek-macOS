import SwiftUI

struct RouteProgressSection: View {
    private let workout = WorkoutManager.shared
    private let store = DataStore.shared
    private let profileManager = ProfileManager.shared

    private var lifetimeKm: Double { MopsMood.lifetimeDistance }
    private var progress: (routeIndex: Int, distanceOnRoute: Double) {
        VirtualRoute.progress(for: lifetimeKm)
    }
    private var route: VirtualRoute { VirtualRoute.allRoutes[progress.routeIndex] }
    private var distanceOnRoute: Double { progress.distanceOnRoute }
    private var routeProgress: Double {
        guard route.totalDistance > 0 else { return 0 }
        return min(distanceOnRoute / route.totalDistance, 1.0)
    }
    private var tourComplete: Bool {
        lifetimeKm >= VirtualRoute.totalTourDistance
    }
    private var currentTour: VirtualRoute.TourDefinition {
        VirtualRoute.tourFor(routeIndex: progress.routeIndex)
    }
    private var routeIndexInTour: Int {
        progress.routeIndex - currentTour.routeRange.lowerBound
    }
    private var routeCountInTour: Int {
        currentTour.routeRange.count
    }

    private var completedTours: [VirtualRoute.TourDefinition] {
        VirtualRoute.TourDefinition.all.filter { tour in
            let tourEnd = VirtualRoute.allRoutes[tour.routeRange].reduce(0.0) { $0 + $1.totalDistance }
            let tourStart = VirtualRoute.cumulativeStart(for: tour.routeRange.lowerBound)
            return lifetimeKm >= tourStart + tourEnd
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "map.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text(tourComplete ? "Wszystkie trasy ukończone!" : "\(route.emoji) \(route.name)")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text("Etap \(routeIndexInTour + 1)/\(routeCountInTour)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Completed tour badges
            if !completedTours.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(completedTours.enumerated()), id: \.element.name) { idx, tour in
                        ZStack {
                            Circle()
                                .fill(.yellow.opacity(0.12))
                                .frame(width: 24, height: 24)
                            Circle()
                                .stroke(
                                    .linearGradient(
                                        colors: [.orange.opacity(0.5), .yellow.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .frame(width: 24, height: 24)
                            Text(tour.emoji)
                                .font(.system(size: 11))
                        }
                    }

                    Spacer()

                    Text("\(completedTours.count) ukończone")
                        .font(.system(size: 8))
                        .foregroundStyle(.orange)
                }
            }

            // Tour name
            HStack(spacing: 3) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text("\(currentTour.emoji) \(currentTour.name)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            if tourComplete {
                completedView
            } else {
                routeMapView
            }

            // Stats row
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                    Text(String(format: "%.1f / %.0f km", distanceOnRoute, route.totalDistance))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                }

                Spacer()

                if let next = nextWaypoint {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                        Text("Do \(next.name): \(String(format: "%.1f", next.distanceFromStart - distanceOnRoute)) km")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Route Map

    private var routeMapView: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let lineY: CGFloat = 14

            ZStack(alignment: .topLeading) {
                // Background line
                Capsule()
                    .fill(.primary.opacity(0.08))
                    .frame(width: width, height: 4)
                    .offset(y: lineY - 2)

                // Explored line with gradient
                Capsule()
                    .fill(
                        .linearGradient(
                            colors: [.green.opacity(0.4), .green.opacity(0.7), .green.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(width * routeProgress, 4), height: 4)
                    .offset(y: lineY - 2)

                // Fog overlay
                Rectangle()
                    .fill(.primary.opacity(0.03))
                    .frame(width: max(width * (1 - routeProgress), 0), height: 28)
                    .offset(x: width * routeProgress)
                    .blur(radius: 2)

                // Waypoint dots and labels
                ForEach(Array(route.waypoints.enumerated()), id: \.offset) { idx, wp in
                    let x = waypointX(wp, totalWidth: width)
                    let visited = distanceOnRoute >= wp.distanceFromStart

                    VStack(spacing: 2) {
                        Circle()
                            .fill(visited ? .green : .primary.opacity(0.15))
                            .frame(width: 7, height: 7)
                            .overlay(
                                Circle()
                                    .stroke(.background, lineWidth: 1)
                            )

                        Text(wp.name)
                            .font(.system(size: 7))
                            .foregroundStyle(visited ? .primary : Color.secondary.opacity(0.6))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .offset(x: x - 4, y: lineY - 4)
                }

                // Pet position
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.2))
                        .frame(width: 14, height: 14)
                        .blur(radius: 2)

                    Image(systemName: profileManager.activeProfile.petType.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }
                .offset(
                    x: max(width * routeProgress - 7, 0),
                    y: lineY - 20
                )
            }
        }
        .frame(height: 44)
    }

    private var completedView: some View {
        HStack {
            Spacer()
            VStack(spacing: 3) {
                Text("🎉")
                    .font(.system(size: 20))
                Text("Wszystkie trasy ukończone!")
                    .font(.system(size: 11, weight: .medium))
                Text(String(format: "Łącznie: %.0f km", lifetimeKm))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func waypointX(_ wp: RouteWaypoint, totalWidth: CGFloat) -> CGFloat {
        guard route.totalDistance > 0 else { return 0 }
        return totalWidth * (wp.distanceFromStart / route.totalDistance)
    }

    private var nextWaypoint: RouteWaypoint? {
        route.waypoints.first { $0.distanceFromStart > distanceOnRoute }
    }
}
