import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showRestoreConfirmation = false
    @State private var selectedBackup: (name: String, date: Date, url: URL)?
    @State private var restoreSuccess: Bool?
    private let profileManager = ProfileManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    Text("Ustawienia")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 2)

                // Profile switcher
                SettingsSection(icon: "person.2.fill", title: "Aktywny profil", color: .purple) {
                    HStack(spacing: 0) {
                        ForEach(profileManager.profiles) { profile in
                            Button {
                                profileManager.switchProfile(to: profile)
                                viewModel.reloadFromSettings()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: profile.petType.icon)
                                        .font(.system(size: 11))
                                    Text(profile.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    profileManager.activeProfile.id == profile.id
                                        ? Color.purple.opacity(0.15)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .foregroundStyle(
                                    profileManager.activeProfile.id == profile.id
                                        ? .primary
                                        : .secondary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(2)
                    .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }

                // Body measurements
                SettingsSection(icon: "figure.stand", title: "Dane fizyczne", color: .blue) {
                    VStack(spacing: 8) {
                        SettingsSliderRow(
                            icon: "scalemass.fill",
                            label: "Waga",
                            value: $viewModel.userWeight,
                            range: 40...180,
                            step: 1,
                            format: "%.0f kg",
                            color: .orange
                        )

                        SettingsSliderRow(
                            icon: "ruler.fill",
                            label: "Wzrost",
                            value: $viewModel.userHeight,
                            range: 140...220,
                            step: 1,
                            format: "%.0f cm",
                            color: .blue
                        )

                        Text("Kalorie obliczane na podstawie MET dla walkpada i Twojej wagi")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)

                        Divider()

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.green)
                                Text("Zapisz wagę")
                                    .font(.system(size: 10))
                            }
                            Spacer()
                            Button("Dodaj \(String(format: "%.0f", viewModel.userWeight)) kg") {
                                let entry = WeightEntry(weight: viewModel.userWeight)
                                DataStore.shared.addWeightEntry(entry)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.mini)
                        }

                        let entries = DataStore.shared.sortedWeightEntries()
                        if let last = entries.last {
                            let formatter = DateFormatter()
                            let _ = formatter.dateFormat = "d MMM"
                            let _ = formatter.locale = Locale(identifier: "pl_PL")
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.green)
                                Text("Ostatni wpis: \(String(format: "%.1f kg", last.weight)) (\(formatter.string(from: last.date)))")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Goals
                SettingsSection(icon: "target", title: "Cele", color: .green) {
                    VStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.green)
                                Text("Cel dzienny")
                                    .font(.system(size: 10, weight: .medium))
                            }

                            HStack {
                                Slider(value: $viewModel.dailyGoalDistance, in: 1...20, step: 0.5)
                                    .tint(.green)
                                Text(String(format: "%.1f km", viewModel.dailyGoalDistance))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(.green)
                                    .frame(width: 50, alignment: .trailing)
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.blue)
                                Text("Sesje tygodniowo")
                                    .font(.system(size: 10, weight: .medium))
                            }

                            Picker("", selection: $viewModel.weeklySessionsTarget) {
                                ForEach(1...7, id: \.self) { n in
                                    Text("\(n)").tag(n)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }

                // Notifications
                SettingsSection(icon: "bell.fill", title: "Powiadomienia", color: .red) {
                    VStack(spacing: 8) {
                        Toggle(isOn: $viewModel.notificationsEnabled) {
                            Text("Włączone")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)

                        if viewModel.notificationsEnabled {
                            Divider()

                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.orange)
                                    Text("Przypomnienie")
                                        .font(.system(size: 10))
                                }
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: $viewModel.reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .controlSize(.small)
                            }

                            Button {
                                NotificationManager.shared.sendTestNotification()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 9))
                                    Text("Wyślij testowe")
                                        .font(.system(size: 10, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .animation(.spring(response: 0.3), value: viewModel.notificationsEnabled)
                }

                // Treadmill Maintenance
                SettingsSection(icon: "wrench.and.screwdriver.fill", title: "Konserwacja bieżni", color: .orange) {
                    let totalKm = DataStore.shared.completedWorkouts().reduce(0.0) { $0 + $1.distance }
                    let kmSinceMaintenance = totalKm - AppSettings.shared.lastMaintenanceKm
                    let interval = AppSettings.shared.maintenanceIntervalKm

                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Od ostatniego olejowania")
                                    .font(.system(size: 10, weight: .medium))
                                HStack(spacing: 4) {
                                    Text(String(format: "%.0f km", kmSinceMaintenance))
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(kmSinceMaintenance >= interval ? .orange : .primary)
                                    Text(String(format: "/ %.0f km", interval))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button("Zresetuj") {
                                AppSettings.shared.lastMaintenanceKm = totalKm
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .controlSize(.mini)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.primary.opacity(0.08))
                                Capsule()
                                    .fill(kmSinceMaintenance >= interval ? Color.orange : .green)
                                    .frame(width: geo.size.width * min(kmSinceMaintenance / interval, 1.0))
                            }
                        }
                        .frame(height: 5)

                        if kmSinceMaintenance >= interval {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.orange)
                                Text("Czas naolejować taśmę bieżni!")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.orange)
                            }
                        }

                        Text("GymTek zaleca olejowanie co 100-200 km")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                }

                // Apple Zdrowie (HealthKit)
                SettingsSection(icon: "heart.fill", title: "Apple Zdrowie", color: .pink) {
                    let hk = HealthKitManager.shared
                    VStack(spacing: 8) {
                        if hk.isAvailable {
                            Toggle(isOn: $viewModel.healthKitEnabled) {
                                HStack(spacing: 4) {
                                    Text("Synchronizuj z Apple Zdrowie")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .toggleStyle(.switch)
                            .controlSize(.small)

                            if viewModel.healthKitEnabled {
                                Divider()

                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(hk.isAuthorized ? .green : .red)
                                        .frame(width: 6, height: 6)
                                    Text(hk.isAuthorized ? "Autoryzowano" : "Brak autoryzacji")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    if !hk.isAuthorized {
                                        Button("Autoryzuj") {
                                            hk.requestAuthorization()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.mini)
                                    }
                                }

                                if hk.isAuthorized {
                                    Divider()

                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Synchronizuj historyczne treningi")
                                                .font(.system(size: 10, weight: .medium))
                                            Text("Wyślij wcześniejsze treningi do Apple Zdrowie")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.tertiary)
                                        }
                                        Spacer()
                                        Button {
                                            hk.syncHistoricalWorkouts()
                                        } label: {
                                            if hk.isSyncing {
                                                ProgressView()
                                                    .controlSize(.small)
                                            } else {
                                                Text("Synchronizuj")
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.mini)
                                        .disabled(hk.isSyncing)
                                    }
                                }

                                if let error = hk.lastError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.orange)
                                        Text(error)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.red)
                                Text("HealthKit niedostępny na tym urządzeniu")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .animation(.spring(response: 0.3), value: viewModel.healthKitEnabled)
                    .animation(.spring(response: 0.3), value: hk.isAuthorized)
                }

                // System
                SettingsSection(icon: "laptopcomputer", title: "System", color: .gray) {
                    VStack(spacing: 8) {
                        Toggle(isOn: $viewModel.launchAtLogin) {
                            HStack(spacing: 4) {
                                Image(systemName: "power")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.green)
                                Text("Uruchamiaj przy logowaniu")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)

                        Divider()

                        HStack(spacing: 12) {
                            Button {
                                viewModel.manualScan()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 9))
                                    Text("Skanuj BLE")
                                        .font(.system(size: 10, weight: .medium))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.mini)

                            Button {
                                viewModel.forgetDevice()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 9))
                                    Text("Zapomnij")
                                        .font(.system(size: 10, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .tint(.red)
                        }

                        Divider()

                        HStack(spacing: 8) {
                            Button {
                                viewModel.exportCSV()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .font(.system(size: 9))
                                    Text("Eksportuj CSV")
                                        .font(.system(size: 10, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)

                            Button {
                                BackupManager.shared.performBackup()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "externaldrive.fill.badge.timemachine")
                                        .font(.system(size: 9))
                                    Text("Backup teraz")
                                        .font(.system(size: 10, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }

                        // Backup status
                        let backup = BackupManager.shared
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.green)
                            if let lastDate = backup.lastBackupDate {
                                let formatter = DateFormatter()
                                let _ = formatter.dateFormat = "d MMM HH:mm"
                                let _ = formatter.locale = Locale(identifier: "pl_PL")
                                Text("Ostatni backup: \(formatter.string(from: lastDate)) (\(backup.backupCount)/7)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Brak backupów — auto codziennie o 19:00")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Restore from backup
                        let backups = backup.availableBackups()
                        if !backups.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Przywróć kopię zapasową")
                                    .font(.system(size: 10, weight: .medium))

                                ForEach(backups, id: \.name) { b in
                                    let formatter = DateFormatter()
                                    let _ = formatter.dateFormat = "d MMM yyyy, HH:mm"
                                    let _ = formatter.locale = Locale(identifier: "pl_PL")

                                    Button {
                                        selectedBackup = b
                                        showRestoreConfirmation = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 8))
                                            Text(formatter.string(from: b.date))
                                                .font(.system(size: 9))
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }

                                if let success = restoreSuccess {
                                    HStack(spacing: 4) {
                                        Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundStyle(success ? .green : .red)
                                        Text(success ? "Przywrócono pomyślnie!" : "Błąd przywracania")
                                            .font(.system(size: 9))
                                            .foregroundStyle(success ? .green : .red)
                                    }
                                }
                            }
                        }
                    }
                }
                .alert("Przywrócić kopię zapasową?", isPresented: $showRestoreConfirmation) {
                    Button("Anuluj", role: .cancel) {}
                    Button("Przywróć", role: .destructive) {
                        if let backup = selectedBackup {
                            let success = BackupManager.shared.restoreBackup(from: backup.url)
                            restoreSuccess = success
                            if success {
                                viewModel.reloadFromSettings()
                            }
                        }
                    }
                } message: {
                    Text("Aktualne dane zostaną zastąpione kopią zapasową. Przed przywróceniem zostanie automatycznie utworzona kopia bezpieczeństwa aktualnych danych. Czy na pewno chcesz kontynuować?")
                }

                // App info
                HStack(spacing: 4) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Text("WalkMate v1.0")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }

            content
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Settings Slider Row

private struct SettingsSliderRow: View {
    let icon: String
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color)
                .frame(width: 12)
            Text(label)
                .font(.system(size: 10))
                .frame(width: 38, alignment: .leading)
            Slider(value: $value, in: range, step: step)
                .tint(color)
            Text(String(format: format, value))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .frame(width: 44, alignment: .trailing)
        }
    }
}
