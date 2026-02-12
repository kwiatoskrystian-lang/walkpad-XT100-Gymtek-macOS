import Foundation

struct RouteWaypoint {
    let name: String
    let distanceFromStart: Double // km
}

struct VirtualRoute {
    let name: String
    let emoji: String
    let totalDistance: Double // km
    let waypoints: [RouteWaypoint]

    // MARK: - Tour de Polska

    static let allRoutes: [VirtualRoute] = [
        VirtualRoute(
            name: "Warszawa → Łódź",
            emoji: "🏙️",
            totalDistance: 135,
            waypoints: [
                RouteWaypoint(name: "Warszawa", distanceFromStart: 0),
                RouteWaypoint(name: "Żyrardów", distanceFromStart: 45),
                RouteWaypoint(name: "Rawa Maz.", distanceFromStart: 85),
                RouteWaypoint(name: "Łódź", distanceFromStart: 135),
            ]
        ),
        VirtualRoute(
            name: "Łódź → Kraków",
            emoji: "🏰",
            totalDistance: 215,
            waypoints: [
                RouteWaypoint(name: "Łódź", distanceFromStart: 0),
                RouteWaypoint(name: "Piotrków Tryb.", distanceFromStart: 45),
                RouteWaypoint(name: "Częstochowa", distanceFromStart: 130),
                RouteWaypoint(name: "Kraków", distanceFromStart: 215),
            ]
        ),
        VirtualRoute(
            name: "Kraków → Zakopane",
            emoji: "⛰️",
            totalDistance: 110,
            waypoints: [
                RouteWaypoint(name: "Kraków", distanceFromStart: 0),
                RouteWaypoint(name: "Myślenice", distanceFromStart: 35),
                RouteWaypoint(name: "Nowy Targ", distanceFromStart: 80),
                RouteWaypoint(name: "Zakopane", distanceFromStart: 110),
            ]
        ),
        VirtualRoute(
            name: "Zakopane → Wrocław",
            emoji: "🌉",
            totalDistance: 340,
            waypoints: [
                RouteWaypoint(name: "Zakopane", distanceFromStart: 0),
                RouteWaypoint(name: "Bielsko-Biała", distanceFromStart: 85),
                RouteWaypoint(name: "Katowice", distanceFromStart: 155),
                RouteWaypoint(name: "Opole", distanceFromStart: 255),
                RouteWaypoint(name: "Wrocław", distanceFromStart: 340),
            ]
        ),
        VirtualRoute(
            name: "Wrocław → Gdańsk",
            emoji: "⛵",
            totalDistance: 460,
            waypoints: [
                RouteWaypoint(name: "Wrocław", distanceFromStart: 0),
                RouteWaypoint(name: "Leszno", distanceFromStart: 80),
                RouteWaypoint(name: "Poznań", distanceFromStart: 175),
                RouteWaypoint(name: "Bydgoszcz", distanceFromStart: 310),
                RouteWaypoint(name: "Gdańsk", distanceFromStart: 460),
            ]
        ),
        VirtualRoute(
            name: "Gdańsk → Warszawa",
            emoji: "🏁",
            totalDistance: 340,
            waypoints: [
                RouteWaypoint(name: "Gdańsk", distanceFromStart: 0),
                RouteWaypoint(name: "Malbork", distanceFromStart: 55),
                RouteWaypoint(name: "Olsztyn", distanceFromStart: 175),
                RouteWaypoint(name: "Warszawa", distanceFromStart: 340),
            ]
        ),

        // MARK: - Camino de Santiago (800 km)

        VirtualRoute(
            name: "Saint-Jean → Pamplona",
            emoji: "🐚",
            totalDistance: 75,
            waypoints: [
                RouteWaypoint(name: "Saint-Jean", distanceFromStart: 0),
                RouteWaypoint(name: "Roncesvalles", distanceFromStart: 25),
                RouteWaypoint(name: "Pamplona", distanceFromStart: 75),
            ]
        ),
        VirtualRoute(
            name: "Pamplona → Burgos",
            emoji: "🐚",
            totalDistance: 155,
            waypoints: [
                RouteWaypoint(name: "Pamplona", distanceFromStart: 0),
                RouteWaypoint(name: "Estella", distanceFromStart: 45),
                RouteWaypoint(name: "Logroño", distanceFromStart: 95),
                RouteWaypoint(name: "Burgos", distanceFromStart: 155),
            ]
        ),
        VirtualRoute(
            name: "Burgos → León",
            emoji: "🐚",
            totalDistance: 190,
            waypoints: [
                RouteWaypoint(name: "Burgos", distanceFromStart: 0),
                RouteWaypoint(name: "Carrión", distanceFromStart: 85),
                RouteWaypoint(name: "Sahagún", distanceFromStart: 130),
                RouteWaypoint(name: "León", distanceFromStart: 190),
            ]
        ),
        VirtualRoute(
            name: "León → Sarria",
            emoji: "🐚",
            totalDistance: 195,
            waypoints: [
                RouteWaypoint(name: "León", distanceFromStart: 0),
                RouteWaypoint(name: "Astorga", distanceFromStart: 50),
                RouteWaypoint(name: "Ponferrada", distanceFromStart: 115),
                RouteWaypoint(name: "Sarria", distanceFromStart: 195),
            ]
        ),
        VirtualRoute(
            name: "Sarria → Santiago",
            emoji: "🐚",
            totalDistance: 185,
            waypoints: [
                RouteWaypoint(name: "Sarria", distanceFromStart: 0),
                RouteWaypoint(name: "Portomarín", distanceFromStart: 22),
                RouteWaypoint(name: "Arzúa", distanceFromStart: 135),
                RouteWaypoint(name: "Santiago", distanceFromStart: 185),
            ]
        ),

        // MARK: - Via Alpina (600 km)

        VirtualRoute(
            name: "Monako → Nicea",
            emoji: "🏔️",
            totalDistance: 30,
            waypoints: [
                RouteWaypoint(name: "Monako", distanceFromStart: 0),
                RouteWaypoint(name: "Nicea", distanceFromStart: 30),
            ]
        ),
        VirtualRoute(
            name: "Nicea → Chamonix",
            emoji: "🏔️",
            totalDistance: 120,
            waypoints: [
                RouteWaypoint(name: "Nicea", distanceFromStart: 0),
                RouteWaypoint(name: "Digne", distanceFromStart: 55),
                RouteWaypoint(name: "Chamonix", distanceFromStart: 120),
            ]
        ),
        VirtualRoute(
            name: "Chamonix → Zermatt",
            emoji: "🏔️",
            totalDistance: 130,
            waypoints: [
                RouteWaypoint(name: "Chamonix", distanceFromStart: 0),
                RouteWaypoint(name: "Martigny", distanceFromStart: 45),
                RouteWaypoint(name: "Zermatt", distanceFromStart: 130),
            ]
        ),
        VirtualRoute(
            name: "Zermatt → Innsbruck",
            emoji: "🏔️",
            totalDistance: 150,
            waypoints: [
                RouteWaypoint(name: "Zermatt", distanceFromStart: 0),
                RouteWaypoint(name: "Brig", distanceFromStart: 35),
                RouteWaypoint(name: "St. Anton", distanceFromStart: 100),
                RouteWaypoint(name: "Innsbruck", distanceFromStart: 150),
            ]
        ),
        VirtualRoute(
            name: "Innsbruck → Triest",
            emoji: "🏔️",
            totalDistance: 170,
            waypoints: [
                RouteWaypoint(name: "Innsbruck", distanceFromStart: 0),
                RouteWaypoint(name: "Cortina", distanceFromStart: 80),
                RouteWaypoint(name: "Triest", distanceFromStart: 170),
            ]
        ),
    ]

    static let totalTourDistance: Double = allRoutes.reduce(0) { $0 + $1.totalDistance }

    // MARK: - Tour definitions

    struct TourDefinition {
        let name: String
        let emoji: String
        let routeRange: Range<Int>
        var totalDistance: Double {
            allRoutes[routeRange].reduce(0) { $0 + $1.totalDistance }
        }

        static let all: [TourDefinition] = [
            TourDefinition(name: "Tour de Polska", emoji: "🇵🇱", routeRange: 0..<6),
            TourDefinition(name: "Camino de Santiago", emoji: "🐚", routeRange: 6..<11),
            TourDefinition(name: "Via Alpina", emoji: "🏔️", routeRange: 11..<16),
        ]
    }

    static func tourFor(routeIndex: Int) -> TourDefinition {
        TourDefinition.all.first { $0.routeRange.contains(routeIndex) } ?? TourDefinition.all.last!
    }

    // MARK: - Progress helpers

    /// Returns (routeIndex, distanceAlongThatRoute) for a given lifetime km.
    static func progress(for lifetimeKm: Double) -> (routeIndex: Int, distanceOnRoute: Double) {
        var remaining = lifetimeKm
        for (i, route) in allRoutes.enumerated() {
            if remaining < route.totalDistance {
                return (i, remaining)
            }
            remaining -= route.totalDistance
        }
        // All routes completed
        return (allRoutes.count - 1, allRoutes.last!.totalDistance)
    }

    /// Cumulative km at the start of this route index.
    static func cumulativeStart(for index: Int) -> Double {
        allRoutes.prefix(index).reduce(0) { $0 + $1.totalDistance }
    }
}
