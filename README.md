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

Aplikacja żyje w pasku menu macOS. Ma animowanego pixel-artowego zwierzaka (mopsika lub szopika), który chodzi razem z Tobą, system celów dziennych, osiągnięcia, wirtualne trasy po Polsce i dużo więcej.

### Funkcje

**Trening**
- Automatyczne wykrywanie i łączenie z bieżnią przez BLE (FTMS)
- Sterowanie prędkością bieżni z poziomu aplikacji (start/stop/szybciej/wolniej)
- Śledzenie na żywo: prędkość, dystans, czas, kalorie (MET), kroki, tętno
- Płynna akumulacja kroków z prędkości (bez skoków)
- Auto-zapis treningu w razie awarii aplikacji
- Wykres prędkości na żywo (sparkline)
- Statystyki na pasku menu podczas treningu

**Cele i motywacja**
- Dzienny cel dystansowy z pierścieniem postępu
- Tygodniowe wyzwania sesji treningowych
- System passów (streak) z tarczami ochronnymi i dniami odpoczynku
- 25+ osiągnięć do odblokowania (dystans, prędkość, streak, sesje)
- System XP i poziomów (Nowicjusz → Legenda)
- Dzienny bonus (losowe nagrody za trening)
- Rywalizacja z własnymi rekordami (vs. ostatni tydzień)

**Zwierzak**
- Pixel-artowy mopsik lub szopik w pasku menu
- 8 animacji idle (stoi, siedzi, śpi, drapie się, kłania, rozciąga...)
- Animacja biegania z pyłem i językiem
- Nastrój zależny od aktywności (wesoły → smutny)
- Ewolucja zwierzaka: bandana (50 km) → plecak (150 km) → peleryna (500 km) → korona (1000 km)
- Dymki z komentarzami po polsku

**Wirtualne trasy**
- "Tour de Polska" — wirtualne spacery między miastami
- Trasy: Warszawa→Łódź, Łódź→Kraków, Kraków→Gdańsk, Gdańsk→Warszawa
- Punkty kontrolne z ciekawostkami o miastach
- Zwierzak wędruje po mapie

**Statystyki**
- Dashboard miesięczny: dystans, czas, kalorie, kroki, aktywne dni
- Porównanie z poprzednim miesiącem (%)
- Wykres dzienny dystansu (Swift Charts)
- Heatmapa aktywności (35 dni)
- Trend prędkości (ostatnie 10 treningów)
- Rekordy osobiste (najdłuższy trening, najszybszy, najdłuższy streak)
- Statystyki lifetime: km, godziny, kroki, kalorie, treningi
- Ulubiony dzień tygodnia i pora dnia
- Najlepszy tydzień w historii

**Inne**
- Eksport historii do CSV
- Backup i przywracanie danych (JSON)
- Przypomnienia o treningu (powiadomienia)
- Przypomnienie o konserwacji paska bieżni (co X km)
- Wskaźnik BMI
- Integracja z Apple Zdrowie (HealthKit) — gotowa, wymaga certyfikatu deweloperskiego
- Efekty dźwiękowe (start/stop/cel)
- Wiele profili użytkowników
- Autostart z systemem
- Ciemny motyw / adaptacyjne tło zależne od pory dnia

### Wymagania

- macOS 14.0 (Sonoma) lub nowszy
- Swift 5.10+ / Xcode Command Line Tools
- Bieżnia z Bluetooth FTMS (testowane z GymTek XT100 / FS-B8D0AC)

### Budowanie

```bash
# Sklonuj repo
git clone https://github.com/kwiatoskrystian-lang/walkpad-XT100-Gymtek-macOS.git
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
    ├── Models/            # Workout, DailyGoal, Achievement, VirtualRoute...
    ├── Services/          # BLEManager, WorkoutManager, GoalsManager...
    ├── Utilities/         # FTMSParser, CalorieCalculator
    ├── ViewModels/        # DashboardVM, StatsVM, HistoryVM...
    └── Views/             # SwiftUI — Dashboard, Stats, Settings, History
Tests/
└── WalkMateTests/         # 21 testów (FTMS parser, cele, osiągnięcia)
```

### Uwagi o BLE (GymTek XT100)

Bieżnia wysyła 2 pakiety FTMS na sekundę:
- **19-bajtowy** z danymi (prędkość, dystans, czas) — flaga bit0=0
- **5-bajtowy** "More Data" — flaga bit0=1, **ignorowany** (parser zwraca nil)

`totalDistance` z bieżni **resetuje się do 0** gdy pas się zatrzymuje — aplikacja używa akumulacji przyrostowej.

---

## EN — English

### What is it?

WalkMate is a native macOS menu bar app that connects to a GymTek XT100 WalkingPad (under-desk treadmill) via Bluetooth Low Energy (FTMS protocol) and tracks your workouts in real time — speed, distance, calories, steps, duration.

It lives in the macOS menu bar with an animated pixel-art pet (pug or raccoon) that walks alongside you, daily goals, achievements, virtual routes across Poland, and much more.

### Features

**Workout Tracking**
- Auto-discovery and connection to treadmill via BLE (FTMS)
- Treadmill speed control from the app (start/stop/faster/slower)
- Live tracking: speed, distance, time, calories (MET-based), steps, heart rate
- Smooth step accumulation from speed (no jumpy increments)
- Auto-save workout on crash recovery
- Live speed sparkline chart
- Menu bar live stats during workout

**Goals & Motivation**
- Daily distance goal with progress ring
- Weekly workout session challenges
- Streak system with shield protection and rest days
- 25+ achievements to unlock (distance, speed, streak, sessions)
- XP and leveling system (Novice → Legend)
- Daily bonus (random rewards for working out)
- Rivalry with your own records (vs. last week)

**Virtual Pet**
- Pixel-art pug or raccoon in the menu bar
- 8 idle animations (standing, sitting, sleeping, scratching, bowing, stretching...)
- Running animation with dust particles and tongue
- Mood depends on activity level (happy → sad)
- Pet evolution: bandana (50 km) → backpack (150 km) → cape (500 km) → crown (1000 km)

**Virtual Routes**
- "Tour de Polska" — virtual walks between Polish cities
- Routes: Warsaw→Lodz, Lodz→Krakow, Krakow→Gdansk, Gdansk→Warsaw
- Checkpoints with city trivia
- Pet travels along the route map

**Statistics**
- Monthly dashboard: distance, time, calories, steps, active days
- Month-over-month comparison (%)
- Daily distance chart (Swift Charts)
- Activity heatmap (35 days)
- Speed trend (last 10 workouts)
- Personal records (longest workout, fastest, longest streak)
- Lifetime stats: km, hours, steps, calories, workouts
- Favorite day of the week and time of day
- Best week ever

**Other**
- CSV history export
- Data backup and restore (JSON)
- Workout reminders (notifications)
- Treadmill belt maintenance reminder (every X km)
- BMI indicator
- Apple Health (HealthKit) integration — ready, requires developer certificate
- Sound effects (start/stop/goal)
- Multiple user profiles
- Launch at login
- Dark theme / adaptive background based on time of day

### Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.10+ / Xcode Command Line Tools
- Bluetooth FTMS treadmill (tested with GymTek XT100 / FS-B8D0AC)

### Building

```bash
# Clone the repo
git clone https://github.com/kwiatoskrystian-lang/walkpad-XT100-Gymtek-macOS.git
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
    ├── Models/            # Workout, DailyGoal, Achievement, VirtualRoute...
    ├── Services/          # BLEManager, WorkoutManager, GoalsManager...
    ├── Utilities/         # FTMSParser, CalorieCalculator
    ├── ViewModels/        # DashboardVM, StatsVM, HistoryVM...
    └── Views/             # SwiftUI — Dashboard, Stats, Settings, History
Tests/
└── WalkMateTests/         # 21 tests (FTMS parser, goals, achievements)
```

### BLE Notes (GymTek XT100)

The treadmill sends 2 FTMS packets per second:
- **19-byte** packet with real data (speed, distance, time) — flags bit0=0
- **5-byte** "More Data" packet — flags bit0=1, **ignored** (parser returns nil)

`totalDistance` from the treadmill **resets to 0** when the belt stops — the app uses incremental accumulation only.

### Architecture

- **MVVM**: Views → ViewModels → Services → Models
- **Persistence**: JSON files in `~/Library/Application Support/WalkMate/`
- **BLE**: CoreBluetooth with FTMS (Fitness Machine Service) protocol
- **UI**: SwiftUI with `MenuBarExtra` (menu bar app, no dock icon)
- **Testing**: Custom test runner (no XCTest dependency)

### Compatibility

Built and tested with GymTek XT100 WalkingPad, but should work with any Bluetooth treadmill that implements the FTMS (Fitness Machine Service) standard — including many models from WalkingPad, Xiaomi, Urevo, Sperax, and others.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
