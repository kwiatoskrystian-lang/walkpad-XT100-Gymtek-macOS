# WalkMate — GymTek XT100 WalkingPad Companion for macOS

<div align="center">

**Aplikacja macOS w pasku menu do śledzenia treningów na bieżni pod biurko**

**macOS menu bar app for tracking under-desk treadmill workouts**

`Swift` `SwiftUI` `Bluetooth LE` `FTMS` `macOS 14+`

</div>

---

## PL — Polski

### Co to jest?

WalkMate to natywna aplikacja macOS, która łączy się z bieżnią GymTek XT100 WalkingPad przez Bluetooth Low Energy (protokół FTMS) i śledzi Twoje treningi w czasie rzeczywistym — prędkość, dystans, kalorie, kroki, czas.

Cała komunikacja odbywa się lokalnie przez Bluetooth — żadne dane nie są wysyłane do internetu. Aplikacja działa jako lokalny serwer BLE, który odbiera pakiety FTMS z bieżni, przetwarza je i zapisuje dane na dysku w formacie JSON.

Aplikacja żyje w pasku menu macOS. Ma animowanego pixel-artowego zwierzaka (mopsika lub szopika), który chodzi razem z Tobą, system celów dziennych, osiągnięcia, wirtualne trasy i dużo więcej.

### Funkcje

**Trening i komunikacja lokalna (BLE)**
- Automatyczne wykrywanie i łączenie z bieżnią przez BLE (FTMS)
- Lokalna komunikacja Bluetooth — zero połączeń sieciowych, pełna prywatność
- Sterowanie prędkością bieżni z poziomu aplikacji (start/stop/pauza/szybciej/wolniej)
- Automatyczna detekcja zakresu prędkości bieżni (min/max)
- Śledzenie na żywo: prędkość, dystans, czas, kalorie (MET), kroki, tętno
- Próbkowanie prędkości co 10 sekund do szczegółowej analityki
- Płynna akumulacja kroków z prędkości (dynamiczna długość kroku na podstawie wzrostu i prędkości)
- Auto-zapis treningu co 30 sekund (odzyskiwanie po awarii)
- 60-sekundowy grace period przy zerwaniu połączenia BLE podczas treningu
- Filtrowanie mikro-treningów (poniżej 5 m automatycznie odrzucane)
- Wykres prędkości na żywo (sparkline)
- Statystyki na pasku menu podczas treningu
- Live coaching — motywacyjne powiadomienia co 5 minut podczas treningu
- Powiadomienia o kamieniach milowych (co 1 km z czasem)
- Inteligentne ponowne łączenie z exponential backoff (1s → 30s)

**Cele i motywacja**
- Dzienny cel dystansowy z pierścieniem postępu
- Tygodniowe wyzwania (3 losowe co tydzień) — dystans, prędkość, sesje, czas trwania
- Wyzwania nagradzane 60–250 XP każde
- System passów (streak) z tarczami ochronnymi (nagradzane przy 7, 30, 60, 100, 150, 200 dniach)
- Jeden dzień odpoczynku na tydzień (ISO pon-ndz) bez utraty streak
- Powiadomienie o zagrożonym streak (codziennie o 19:00)
- 30+ osiągnięć do odblokowania (dystans, prędkość, streak, sesje, sezonowe, trasy)
- Osiągnięcia sezonowe — 4 pory roku, wymagające 42–60 km w sezonie
- System XP i 10 poziomów (Nowicjusz → Legenda)
- Źródła XP: treningi (100 XP/km), streak (15 XP/dzień), osiągnięcia (50 XP), wyzwania, bonusy
- Dzienny bonus — losowy spin z mnożnikami (×1.5 / ×2.0 / ×3.0) za pierwszy trening dnia
- Rywalizacja między profilami (tygodniowy leaderboard z dystansem)
- Porównanie z własnymi rekordami (vs. ostatni tydzień)

**Zwierzak**
- Pixel-artowy mopsik lub szopik w pasku menu
- 8 animacji idle (stoi, siedzi, śpi, drapie się, kłania, rozciąga...)
- Animacja biegania z pyłem i językiem
- Nastrój zależny od aktywności (wesoły → smutny)
- Ewolucja zwierzaka: bandana (50 km) → plecak (150 km) → peleryna (500 km) → korona (1000 km)
- 10 odblokowanych sztuczek (machanie, serce, taniec, skok, obrót, iskry...)
- Kosmetyczne skiny odblokowywane na poziomach 3, 5, 7, 9, 10
- Dymki z komentarzami po polsku

**Wirtualne trasy**
- **Tour de Polska** — 6 tras, ~1600 km (Warszawa → Łódź → Kraków → Zakopane → Wrocław → Gdańsk → Warszawa)
- **Camino de Santiago** — 5 tras, ~800 km (Saint-Jean → Pamplona → Burgos → León → Sarria → Santiago)
- **Via Alpina** — 5 tras, ~600 km (Monaco → Nice → Chamonix → Zermatt → Innsbruck → Triest)
- 16 wirtualnych tras z punktami kontrolnymi i ciekawostkami
- Osiągnięcia za ukończenie każdego tour
- Zwierzak wędruje po mapie

**Statystyki i analiza**
- Dashboard miesięczny: dystans, czas, kalorie, kroki, aktywne dni
- Porównanie z poprzednim miesiącem i tygodniem (% zmiana z porównaniem kalorii)
- Wykres dzienny dystansu (Swift Charts)
- Heatmapa aktywności (35 dni)
- Trend prędkości (ostatnie 10 treningów, porównanie ostatnich 3 vs poprzednich 3)
- Rekordy osobiste (najdłuższy trening, najszybszy, najdłuższy streak)
- Statystyki lifetime: km, godziny, kroki, kalorie, treningi
- Ulubiony dzień tygodnia i pora dnia
- Najlepszy tydzień w historii
- Prognoza tygodniowa na podstawie aktualnego tempa
- Automatyczne insighty porównujące wyniki tydzień do tygodnia i miesiąc do miesiąca

**Powiadomienia**
- Przypomnienia o treningu
- Ostrzeżenie weekendowe (sobota 10:00) jeśli za mało sesji
- Podsumowanie tygodniowe (niedziela 20:00) — km, sesje, najlepszy trening, streak
- Podsumowanie dzienne (21:00) — dystans, kalorie, cel, streak
- Powiadomienia o ukończonych wyzwaniach
- Coaching na żywo podczas treningu

**Dane i prywatność**
- Wszystkie dane przechowywane lokalnie w `~/Library/Application Support/WalkMate/`
- Eksport historii do CSV
- Automatyczny backup codziennie o 19:00 z rotacją 7 dni
- Backup wszystkich profili (nie tylko aktywnego)
- Przywracanie danych z dowolnego backupu (z safety backup przed restore)
- Śledzenie wagi z historią wpisów
- Integracja z Apple Zdrowie (HealthKit) z synchronizacją historyczną i deduplikacją
- Przypomnienie o konserwacji paska bieżni (domyślnie co 150 km, konfigurowalny interwał)
- Wskaźnik BMI
- Efekty dźwiękowe (start/stop/cel)
- Wiele profili użytkowników z izolowanymi danymi
- Autostart z systemem
- Ciemny motyw / adaptacyjne tło zależne od pory dnia

### Wymagania

- macOS 14.0 (Sonoma) lub nowszy
- Swift 5.10+ / Xcode Command Line Tools
- Bieżnia z Bluetooth FTMS (testowane z GymTek XT100 / FS-B8D0AC)

### Budowanie

```bash
# Sklonuj repo
git clone https://github.com/yourusername/walkpad-XT100-Gymtek-macOS.git
cd walkpad-XT100-Gymtek-macOS

# Zbuduj
swift build

# Uruchom testy (21 testów)
swift run WalkMateTests

# Zbuduj .app bundle
bash build-app.sh

# Uruchom
open .build/WalkMate.app
```

### Struktura projektu

```
Sources/
├── WalkMate/              # Punkt wejścia aplikacji (@main)
└── WalkMateLib/           # Cała logika
    ├── Models/            # Workout, DailyGoal, Achievement, VirtualRoute, XPLevel...
    ├── Services/          # BLEManager, WorkoutManager, GoalsManager, BackupManager...
    ├── Utilities/         # FTMSParser, CalorieCalculator, BLEConstants
    ├── ViewModels/        # DashboardVM, StatsVM, HistoryVM, SettingsVM...
    └── Views/             # SwiftUI — Dashboard, Stats, Settings, History, Achievements
Tests/
└── WalkMateTests/         # 21 testów (FTMS parser, cele, osiągnięcia)
```

### Komunikacja lokalna (BLE)

Aplikacja działa jako **lokalny klient Bluetooth Low Energy** — łączy się bezpośrednio z bieżnią bez żadnego serwera zewnętrznego ani połączenia internetowego.

**Przepływ danych:**
1. Bieżnia rozgłasza usługę FTMS (UUID `1826`) przez BLE
2. Aplikacja skanuje i łączy się automatycznie z urządzeniem o prefiksie `FS-`
3. Subskrybuje charakterystyki FTMS (dane bieżni `2ACD`, status `2AD3`, control point `2AD9`)
4. Odbiera 2 pakiety FTMS na sekundę i przetwarza je lokalnie
5. Wysyła komendy sterujące (start/stop/prędkość) przez control point
6. Wszystkie dane zapisywane lokalnie jako JSON — zero komunikacji sieciowej

**Szczegóły pakietów:**
- **19-bajtowy** z danymi (prędkość, dystans, czas) — flaga bit0=0
- **5-bajtowy** "More Data" — flaga bit0=1, **ignorowany** (parser zwraca nil)

`totalDistance` z bieżni **resetuje się do 0** gdy pas się zatrzymuje — aplikacja używa akumulacji przyrostowej.

---

## EN — English

### What is it?

WalkMate is a native macOS menu bar app that connects to a GymTek XT100 WalkingPad (under-desk treadmill) via Bluetooth Low Energy (FTMS protocol) and tracks your workouts in real time — speed, distance, calories, steps, duration.

All communication happens locally over Bluetooth — no data is sent to the internet. The app acts as a local BLE client, receiving FTMS packets from the treadmill, processing them, and storing data on disk as JSON files.

It lives in the macOS menu bar with an animated pixel-art pet (pug or raccoon) that walks alongside you, daily goals, achievements, virtual routes, and much more.

### Features

**Workout Tracking & Local BLE Communication**
- Auto-discovery and connection to treadmill via BLE (FTMS)
- Local Bluetooth communication — zero network calls, full privacy
- Treadmill speed control from the app (start/stop/pause/faster/slower)
- Automatic speed range detection (min/max from treadmill)
- Live tracking: speed, distance, time, calories (MET-based), steps, heart rate
- Speed sampling every 10 seconds for detailed analytics
- Smooth step accumulation from speed (dynamic step length based on height and speed)
- Auto-save workout every 30 seconds (crash recovery)
- 60-second grace period on BLE disconnect during workout
- Micro-workout filtering (under 5 m automatically discarded)
- Live speed sparkline chart
- Menu bar live stats during workout
- Live coaching — motivational notifications every 5 minutes during workout
- Kilometer milestone notifications with elapsed time
- Smart reconnection with exponential backoff (1s → 30s)

**Goals & Motivation**
- Daily distance goal with progress ring
- Weekly challenges (3 random per week) — distance, speed, sessions, duration
- Challenges award 60–250 XP each
- Streak system with shield protection (awarded at 7, 30, 60, 100, 150, 200 days)
- One rest day per week (ISO Mon-Sun) without breaking streak
- Streak at risk notification (daily at 19:00)
- 30+ achievements to unlock (distance, speed, streak, sessions, seasonal, routes)
- Seasonal achievements — 4 seasons, requiring 42–60 km within each season
- XP system with 10 levels (Novice → Legend)
- XP sources: workouts (100 XP/km), streaks (15 XP/day), achievements (50 XP), challenges, bonuses
- Daily spin bonus — random multiplier (×1.5 / ×2.0 / ×3.0) for first workout of the day
- Multi-profile rivalry (weekly distance leaderboard)
- Rivalry with your own records (vs. last week)

**Virtual Pet**
- Pixel-art pug or raccoon in the menu bar
- 8 idle animations (standing, sitting, sleeping, scratching, bowing, stretching...)
- Running animation with dust particles and tongue
- Mood depends on activity level (happy → sad)
- Pet evolution: bandana (50 km) → backpack (150 km) → cape (500 km) → crown (1000 km)
- 10 unlockable pet tricks (wave, heart, dance, jump, spin, sparkle...)
- Cosmetic skins unlocked at levels 3, 5, 7, 9, 10
- Speech bubbles with comments

**Virtual Routes**
- **Tour de Polska** — 6 routes, ~1600 km (Warsaw → Lodz → Krakow → Zakopane → Wroclaw → Gdansk → Warsaw)
- **Camino de Santiago** — 5 routes, ~800 km (Saint-Jean → Pamplona → Burgos → Leon → Sarria → Santiago)
- **Via Alpina** — 5 routes, ~600 km (Monaco → Nice → Chamonix → Zermatt → Innsbruck → Trieste)
- 16 virtual routes with checkpoints and trivia
- Achievements for completing each tour
- Pet travels along the route map

**Statistics & Insights**
- Monthly dashboard: distance, time, calories, steps, active days
- Week-over-week and month-over-month comparison (% change with calorie comparison)
- Daily distance chart (Swift Charts)
- Activity heatmap (35 days)
- Speed trend (last 10 workouts, comparing recent 3 vs previous 3)
- Personal records (longest workout, fastest, longest streak)
- Lifetime stats: km, hours, steps, calories, workouts
- Favorite day of the week and time of day
- Best week ever
- Weekly forecast based on current pace
- Automated insights comparing performance across weeks and months

**Notifications**
- Workout reminders
- Weekend warning (Saturday 10:00) if behind on weekly session target
- Weekly summary (Sunday 20:00) — km, sessions, best workout, streak
- Daily summary (21:00) — distance, calories, goal status, streak
- Challenge completion alerts
- Live coaching during workouts

**Data & Privacy**
- All data stored locally in `~/Library/Application Support/WalkMate/`
- CSV history export
- Automatic daily backup at 19:00 with 7-day rotation
- Backup covers all profiles (not just active)
- Restore from any backup (with safety backup before restore)
- Weight tracking with history
- Apple Health (HealthKit) integration with historical sync and deduplication
- Treadmill belt maintenance reminder (default every 150 km, configurable)
- BMI indicator
- Sound effects (start/stop/goal)
- Multiple user profiles with isolated data storage
- Launch at login
- Dark theme / adaptive background based on time of day

### Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.10+ / Xcode Command Line Tools
- Bluetooth FTMS treadmill (tested with GymTek XT100 / FS-B8D0AC)

### Building

```bash
# Clone the repo
git clone https://github.com/yourusername/walkpad-XT100-Gymtek-macOS.git
cd walkpad-XT100-Gymtek-macOS

# Build
swift build

# Run tests (21 tests)
swift run WalkMateTests

# Build .app bundle
bash build-app.sh

# Run
open .build/WalkMate.app
```

### Project Structure

```
Sources/
├── WalkMate/              # App entry point (@main)
└── WalkMateLib/           # All logic
    ├── Models/            # Workout, DailyGoal, Achievement, VirtualRoute, XPLevel...
    ├── Services/          # BLEManager, WorkoutManager, GoalsManager, BackupManager...
    ├── Utilities/         # FTMSParser, CalorieCalculator, BLEConstants
    ├── ViewModels/        # DashboardVM, StatsVM, HistoryVM, SettingsVM...
    └── Views/             # SwiftUI — Dashboard, Stats, Settings, History, Achievements
Tests/
└── WalkMateTests/         # 21 tests (FTMS parser, goals, achievements)
```

### Local BLE Communication

The app acts as a **local Bluetooth Low Energy client** — it connects directly to the treadmill with no external server or internet connection.

**Data flow:**
1. Treadmill advertises FTMS service (UUID `1826`) over BLE
2. App scans and auto-connects to devices with `FS-` prefix
3. Subscribes to FTMS characteristics (treadmill data `2ACD`, status `2AD3`, control point `2AD9`)
4. Receives 2 FTMS packets per second and processes them locally
5. Sends control commands (start/stop/speed) via control point
6. All data saved locally as JSON — zero network communication

**Packet details:**
- **19-byte** packet with real data (speed, distance, time) — flags bit0=0
- **5-byte** "More Data" packet — flags bit0=1, **ignored** (parser returns nil)

`totalDistance` from the treadmill **resets to 0** when the belt stops — the app uses incremental accumulation only.

### Architecture

- **MVVM**: Views → ViewModels → Services → Models
- **Persistence**: JSON files in `~/Library/Application Support/WalkMate/` (per-profile isolation)
- **BLE**: CoreBluetooth with FTMS (Fitness Machine Service) protocol
- **UI**: SwiftUI with `MenuBarExtra` (menu bar app, no dock icon)
- **Backup**: Automatic daily JSON backup with 7-day rotation
- **Testing**: Custom test runner (no XCTest dependency)

### Compatibility

Built and tested with GymTek XT100 WalkingPad, but should work with any Bluetooth treadmill that implements the FTMS (Fitness Machine Service) standard — including many models from WalkingPad, Xiaomi, Urevo, Sperax, and others.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
