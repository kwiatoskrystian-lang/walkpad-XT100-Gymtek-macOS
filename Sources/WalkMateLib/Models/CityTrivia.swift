import Foundation

/// Fun facts about cities on the virtual routes. The pet says these when the user reaches a waypoint.
enum CityTrivia {
    static let facts: [String: [String]] = [
        // Tour de Polska
        "Warszawa": [
            "Warszawa ma więcej parków niż Paryż!",
            "Pałac Kultury ma 3288 pokoi.",
            "Syrenka warszawska to symbol miasta od XV wieku.",
        ],
        "Żyrardów": [
            "Żyrardów ma największy w Europie kompleks pofabryczny z czerwonej cegły.",
            "Nazwa miasta pochodzi od Filipa de Girard — wynalazcy maszyny do lnu.",
        ],
        "Rawa Maz.": [
            "Rawa Mazowiecka ma jedne z najstarszych ruin zamkowych w Polsce.",
        ],
        "Łódź": [
            "Łódź ma najdłuższą ulicę handlową w Europie — Piotrkowską (4.2 km).",
            "Łódź była Hollywoodem Europy — tu kręcono pierwsze polskie filmy!",
            "W Łodzi jest ponad 200 murali street-artowych.",
        ],
        "Piotrków Tryb.": [
            "Piotrków Trybunalski był siedzibą Trybunału Koronnego — najwyższego sądu I RP.",
        ],
        "Częstochowa": [
            "Na Jasną Górę pielgrzymuje rocznie ~4 miliony osób.",
            "Obraz Czarnej Madonny ma ponad 600 lat.",
        ],
        "Kraków": [
            "Hejnał z Wieży Mariackiej urywa się nagle — na pamiątkę tatarskiego strzałą trafieniu trębacza.",
            "Kraków ma ponad 100 kościołów!",
            "Smok Wawelski zjadał podobno 3 krowy dziennie.",
        ],
        "Myślenice": [
            "Myślenice słyną z największego w Polsce parku linowego.",
        ],
        "Nowy Targ": [
            "Nowy Targ jest stolicą Podhala i bramą do Tatr.",
        ],
        "Zakopane": [
            "Zakopane leży na 800-1000 m n.p.m. — najwyżej położone miasto w Polsce.",
            "Krupówki mają tylko 1 km długości, ale rocznie odwiedza je 3 mln turystów.",
            "Oscypek jest chroniony prawem UE jako produkt regionalny.",
        ],
        "Bielsko-Biała": [
            "Bielsko-Biała to \"mały Wiedeń\" — pełna secesyjnej architektury.",
        ],
        "Katowice": [
            "Spodek w Katowicach waży 12 000 ton — tyle co 2000 słoni.",
            "Katowice są Miastem Muzyki UNESCO od 2015 roku.",
        ],
        "Opole": [
            "Opole to najstarsze miasto na Śląsku — prawa miejskie od 1217 r.",
            "Co roku odbywa się tu Krajowy Festiwal Polskiej Piosenki.",
        ],
        "Wrocław": [
            "Wrocław ma 112 mostów — więcej niż Wenecja!",
            "Po mieście ukrytych jest ponad 300 krasnali-figurek.",
            "Wrocław leży na 12 wyspach połączonych mostami.",
        ],
        "Leszno": [
            "Leszno było centrum braci czeskich — protestantów uciekających z Czech.",
        ],
        "Poznań": [
            "Koziołki poznańskie trykają się codziennie w południe na wieży ratusza.",
            "Poznań ma najstarszą katedrę w Polsce — z 968 roku.",
            "Rogale marcińskie mają chroniony przepis — ciasto musi mieć 81 warstw!",
        ],
        "Bydgoszcz": [
            "Bydgoszcz jest polską Wenecją — kanał Brdy przecina centrum miasta.",
        ],
        "Gdańsk": [
            "Gdańsk był najbogatszym miastem I Rzeczypospolitej.",
            "Żuraw gdański to największy średniowieczny dźwig portowy w Europie.",
            "Tu zaczęła się Solidarność — ruch, który zmienił Europę.",
        ],
        "Malbork": [
            "Zamek w Malborku jest największym zamkiem na świecie (mierzony powierzchnią).",
            "Budowa zamku trwała ponad 230 lat.",
        ],
        "Olsztyn": [
            "Mikołaj Kopernik był administratorem zamku w Olsztynie.",
            "Olsztyn ma 15 jezior w granicach miasta!",
        ],

        // Camino de Santiago
        "Saint-Jean": [
            "Saint-Jean-Pied-de-Port to tradycyjny początek Camino Frances.",
        ],
        "Roncesvalles": [
            "W Roncesvalles zginął Roland — bohater średniowiecznej epiki.",
        ],
        "Pamplona": [
            "Pamplona słynie z gonitwy byków — San Fermín w lipcu.",
            "Ernest Hemingway pisał o Pamplonie w \"Słońce też wschodzi\".",
        ],
        "Estella": [
            "Estella była nazywana \"Toledo Północy\" za piękną architekturę.",
        ],
        "Logroño": [
            "Logroño to stolica regionu La Rioja — najsłynniejszych win Hiszpanii.",
        ],
        "Burgos": [
            "Katedra w Burgos jest jedną z najpiękniejszych gotyckich katedr na świecie.",
            "Tu pochowany jest El Cid — legendarny rycerz.",
        ],
        "Carrión": [
            "Carrión de los Condes ma klasztor z XII w. z unikalnymi rzeźbami.",
        ],
        "Sahagún": [
            "Sahagún to \"Cluny Hiszpanii\" — było centrum reformy benedyktyńskiej.",
        ],
        "León": [
            "Katedra w León ma 1800 m² witraży — nazywana \"Domem Światła\".",
        ],
        "Astorga": [
            "W Astordze stoi Pałac Biskupi zaprojektowany przez Gaudíego!",
        ],
        "Ponferrada": [
            "Zamek templariuszy w Ponferradzie chronił pielgrzymów od XII wieku.",
        ],
        "Sarria": [
            "Sarria to najpopularniejszy punkt startowy Camino — ostatnie 100 km.",
        ],
        "Portomarín": [
            "Całe stare miasto Portomarín przeniesiono wyżej, gdy zalał je zbiornik.",
        ],
        "Arzúa": [
            "Arzúa słynie z sera Arzúa-Ulloa — kremowego galicyjskiego sera.",
        ],
        "Santiago": [
            "Katedra w Santiago kryje relikwie św. Jakuba Apostoła.",
            "Pielgrzymi przechodzą ~800 km, by tu dotrzeć!",
        ],

        // Via Alpina
        "Monako": [
            "Monako jest drugim najmniejszym państwem świata — 2 km².",
            "1 na 3 mieszkańców Monako jest milionerem.",
        ],
        "Nicea": [
            "Promenada Anglików w Nicei ma 7 km — idealna na spacer.",
        ],
        "Digne": [
            "Digne-les-Bains ma gorące źródła termalne znane od czasów rzymskich.",
        ],
        "Chamonix": [
            "Chamonix gościło pierwsze Zimowe Igrzyska Olimpijskie w 1924 roku.",
            "Mont Blanc nad Chamonix ma 4808 m — najwyższy szczyt Alp.",
        ],
        "Martigny": [
            "Martigny ma ruiny rzymskiego amfiteatru z I wieku n.e.",
        ],
        "Zermatt": [
            "Matterhorn przy Zermatt jest na opakowaniu czekolady Toblerone.",
            "W Zermatt zakaz samochodów spalinowych — tylko elektryczne!",
        ],
        "Brig": [
            "Pałac Stockalper w Brig to największa prywatna rezydencja w Szwajcarii.",
        ],
        "St. Anton": [
            "St. Anton am Arlberg to kolebka narciarstwa alpejskiego.",
        ],
        "Innsbruck": [
            "Innsbruck 2x gościł Zimowe Igrzyska — 1964 i 1976.",
            "Złoty Dach ma 2657 złoconych dachówek miedzianych.",
        ],
        "Cortina": [
            "Cortina d'Ampezzo będzie gospodarzem Zimowych Igrzysk 2026!",
        ],
        "Triest": [
            "Triest był największym portem Austro-Węgier.",
            "James Joyce mieszkał w Trieście i tu pisał \"Ulissesa\".",
        ],
    ]

    /// Returns a random trivia for a city, or nil if none available.
    static func randomFact(for cityName: String) -> String? {
        // Try exact match first, then prefix match for shortened names
        if let list = facts[cityName] {
            return list.randomElement()
        }
        for (key, list) in facts {
            if key.hasPrefix(cityName) || cityName.hasPrefix(key) {
                return list.randomElement()
            }
        }
        return nil
    }

    /// Returns the last visited waypoint name for given route progress.
    /// Includes the starting city (distanceFromStart == 0).
    static func lastVisitedCity(route: VirtualRoute, distanceOnRoute: Double) -> String? {
        route.waypoints
            .filter { $0.distanceFromStart <= distanceOnRoute }
            .last?
            .name
    }
}
