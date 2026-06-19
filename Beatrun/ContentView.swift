import SwiftUI
import UIKit

private enum BeatrunRoute: Hashable {
    case recommendations
    case tempoDetails
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("beatrun.language") private var languageRawValue = AppLanguage.followSystem.rawValue
    @State private var model = BeatrunModel()
    @State private var showingSettings = false

    private var language: AppLanguage {
        AppLanguage.preferred(from: languageRawValue)
    }

    private var copy: AppCopy {
        AppCopy(language: language)
    }

    private var appLocale: Locale {
        Locale(identifier: language.localeIdentifier ?? Locale.current.identifier)
    }

    private var localizedVocalDescription: String {
        switch model.vocalPreference {
        case .instrumental:
            language.effectiveUsesChinese ? "优先使用 BPM 清晰的纯音乐曲目。" : VocalPreference.instrumental.description
        case .vocal:
            language.effectiveUsesChinese ? "优先使用带合法播放元数据的人声风格曲目。" : VocalPreference.vocal.description
        }
    }

    private func localizedVocalTitle(_ preference: VocalPreference) -> String {
        switch preference {
        case .instrumental:
            language.effectiveUsesChinese ? "纯音乐" : preference.title
        case .vocal:
            language.effectiveUsesChinese ? "人声风格" : preference.title
        }
    }

    private var localizedMusicLibraryActionTitle: String {
        guard language.effectiveUsesChinese else { return model.musicLibraryActionTitle }
        return switch model.musicLibraryState {
        case .notDetermined:
            "授权"
        case .authorized:
            "重扫"
        case .denied, .restricted:
            "设置"
        case .unavailable:
            "重试"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if #available(iOS 26.0, *) {
                    GlassEffectContainer(spacing: 16) {
                        dashboardContent
                    }
                    .padding(.top, 12)
                } else {
                    dashboardContent
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color.blue.opacity(0.08),
                        Color.green.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Beatrun")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(copy("open.settings"))
                }
            }
            .navigationDestination(for: BeatrunRoute.self) { route in
                switch route {
                case .recommendations:
                    BeatrunRecommendationsView(model: model, copy: copy)
                case .tempoDetails:
                    BeatrunTempoDetailsView(model: model, copy: copy)
                }
            }
        }
        .environment(\.locale, appLocale)
        .sheet(isPresented: $showingSettings) {
            BeatrunSettingsView(
                model: model,
                languageRawValue: $languageRawValue,
                copy: copy,
                openAppSettings: openAppSettings
            )
            .environment(\.locale, appLocale)
        }
        .task {
#if DEBUG
            if let override = AppLanguage.debugOverride() {
                languageRawValue = override.rawValue
            }
            let simulateDeniedLibrary = CommandLine.arguments.contains("-BeatrunDemoDeniedLibrary")
            if simulateDeniedLibrary {
                model.simulateDeniedMusicLibraryForDemo()
            } else {
                model.prepareMusicLibraryOnLaunch()
            }
            if CommandLine.arguments.contains("-BeatrunDemoAutoplay") {
                try? await Task.sleep(for: .milliseconds(700))
                model.startPlayback()
            }
            if CommandLine.arguments.contains("-BeatrunOpenSettings") {
                try? await Task.sleep(for: .milliseconds(500))
                showingSettings = true
            }
#else
            model.prepareMusicLibraryOnLaunch()
#endif
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            model.refreshMusicLibraryAfterSettingsReturn()
        }
    }

    private var dashboardContent: some View {
        VStack(spacing: 16) {
            dashboardHeader
            cadencePanel
            musicLibraryPanel
            nowPlayingPanel
            recommendationsPanel
        }
        .padding(16)
    }

    private var dashboardHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(copy("run.mix"))
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                Text(copy("run.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            statusChip(
                icon: "applewatch",
                title: model.watchSyncStatus,
                color: .teal
            )
        }
        .padding(.horizontal, 2)
    }

    private var cadencePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy("cadence.target"))
                        .font(.headline)
                    Text(copy("spm"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(model.cadence)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                statusChip(icon: "link", title: "1:1 BPM", color: .blue)
                statusChip(icon: "speedometer", title: "+/-10%", color: .green)
                statusChip(icon: "music.note.list", title: copy("library"), color: .orange)
            }

            Slider(
                value: Binding(
                    get: { Double(model.cadence) },
                    set: { model.setCadence(Int($0.rounded())) }
                ),
                in: 140...200,
                step: 1
            )
            .accessibilityLabel(copy("cadence.target"))

            HStack {
                cadencePresetButton(160)
                cadencePresetButton(170)
                cadencePresetButton(180)
                cadencePresetButton(190)
            }

            Picker(
                copy("music.type"),
                selection: Binding(
                    get: { model.vocalPreference },
                    set: { model.setVocalPreference($0) }
                )
            ) {
                ForEach(VocalPreference.allCases) { preference in
                    Text(localizedVocalTitle(preference)).tag(preference)
                }
            }
            .pickerStyle(.segmented)

            Text(localizedVocalDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .beatrunPanelSurface(tint: .blue)
    }

    private var musicLibraryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: model.musicLibraryState.systemImage)
                    .font(.title3)
                    .foregroundStyle(model.musicLibraryState == .authorized ? Color.green : Color.orange)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(copy("library"))
                        .font(.headline)
                    Text(model.musicLibraryState.title)
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                musicLibraryActionButton
            }

            Text(model.musicLibraryMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                libraryMetric("Scanned", "\(model.scannedLibraryTrackCount)")
                libraryMetric("Retiming", "\(model.retimeReadyTrackCount)")
                libraryMetric("Needs BPM", "\(model.tracksNeedingBPMCount)")
                libraryMetric("Metadata", "\(model.metadataOnlyTrackCount)")
            }

            Text(copy("legal.note"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(18)
        .beatrunPanelSurface(tint: model.musicLibraryState == .authorized ? .green : .orange)
    }

    private var musicLibraryActionButton: some View {
        Button {
            if model.shouldOpenSettingsForMusicLibrary {
                openAppSettings()
            } else {
                model.requestMusicLibraryAccess()
            }
        } label: {
            Label(localizedMusicLibraryActionTitle, systemImage: model.musicLibraryActionSystemImage)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .accessibilityLabel(model.shouldOpenSettingsForMusicLibrary ? copy("library.open.settings") : copy("library.scan"))
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
    }

    private var nowPlayingPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(copy("now.playing"), systemImage: model.metronome.isRunning ? "waveform.path.ecg" : "waveform.path")
                        .font(.headline)

                    Text(model.nowPlayingMatch?.track.title ?? copy("no.legal.match"))
                        .font(.title2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(model.nowPlayingMatch.map { "\($0.adjustment.originalBPM) -> \($0.adjustment.adjustedBPM) BPM • \($0.adjustment.speedChangeLabel)" } ?? copy("beat.rules"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer()

                Button {
                    model.togglePlayback()
                } label: {
                    Image(systemName: model.metronome.isRunning ? "pause.fill" : "play.fill")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .accessibilityLabel(model.metronome.isRunning ? "Pause playback" : "Start playback")
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(model.metronome.musicStatus, systemImage: "music.note")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(model.metronome.audioError == nil ? Color.secondary : Color.red)

                    Spacer()

                    Text("\(copy("playback")) \(Int(model.metronome.musicVolume * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                QueueTransitionView(
                    currentMatch: model.nowPlayingMatch,
                    upcomingMatch: model.upcomingMatch,
                    queueStatus: model.metronome.queueStatus,
                    transitionStatus: model.metronome.transitionStatus,
                    beatsRemaining: model.metronome.transitionBeatsRemaining,
                    isCrossfading: model.metronome.isCrossfading,
                    nextTrackReady: model.metronome.nextTrackReady
                )

                Slider(
                    value: Binding(
                        get: { model.metronome.musicVolume },
                        set: { model.metronome.setMusicVolume($0) }
                    ),
                    in: 0...1,
                    step: 0.05
                )
                .accessibilityLabel(copy("backing.volume"))

                HStack {
                    Label(model.metronome.audioStatus, systemImage: model.metronome.isRunning ? "speaker.wave.2.fill" : "speaker.wave.1")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(model.metronome.audioError == nil ? Color.secondary : Color.red)

                    Spacer()

                    Text("Click \(Int(model.metronome.volume * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { model.metronome.volume },
                        set: { model.metronome.setVolume($0) }
                    ),
                    in: 0...1,
                    step: 0.05
                )
                .accessibilityLabel(copy("click.volume"))

                Text(model.nowPlayingMatch.map { "\($0.track.source.title) • \($0.track.analysisLabel) • \($0.track.playbackCapabilityLabel)" } ?? "Music library source pending")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SyncRuntimeStatus(
                    status: model.metronome.syncStatus,
                    mode: model.metronome.syncMode,
                    offsetMilliseconds: model.metronome.syncOffsetMilliseconds
                )

                if let audioError = model.metronome.audioError {
                    Text(audioError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(12)
            .beatrunInsetSurface(tint: .blue)

            if let selectedMatch = model.nowPlayingMatch {
                NavigationLink(value: BeatrunRoute.tempoDetails) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(copy("match.details"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("\(selectedMatch.track.artist) • \(selectedMatch.track.genre) • \(selectedMatch.syncLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .beatrunInsetSurface(tint: .green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .beatrunPanelSurface(tint: model.metronome.isRunning ? .green : .blue)
    }

    private var recommendationsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy("authorized.tracks"))
                        .font(.headline)

                    Text("\(copy("matches")): \(model.cadence) \(copy("spm"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    model.discoverMusic()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(copy("scan.again"))
            }

            DiscoveryStatusView(
                phase: model.discoveryPhase,
                message: model.discoveryMessage,
                autoMatchMessage: model.autoMatchMessage,
                searchCount: model.searchCount,
                matchCount: model.recommendations.count,
                sourceTitle: model.usingStarterFallback ? "Imported/CC0" : copy("library"),
                sourceNote: model.usingStarterFallback ? copy("imported.cc") : MusicSource.localLibrary.usageNote,
                tracksNeedingBPM: model.tracksNeedingBPMCount,
                metadataOnlyCount: model.metadataOnlyTrackCount,
                copy: copy
            )

            if model.discoveryPhase == .searching || model.discoveryPhase == .analyzing {
                ProgressView()
            }

            ForEach(model.recommendations.prefix(3)) { match in
                TrackRow(
                    match: match,
                    isSelected: match.id == model.selectedMatch?.id
                ) {
                    model.select(match)
                }
            }

            NavigationLink(value: BeatrunRoute.recommendations) {
                Label(copy("open.recommendations"), systemImage: "music.note.list")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .beatrunPanelSurface(tint: .purple)
    }

    private var roadmapPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Competition MVP")
                .font(.headline)

            FeatureStatusRow(icon: "music.note.list", title: "Music matching", status: "Library/CC")
            FeatureStatusRow(icon: "metronome", title: "Metronome", status: "Audio click")
            FeatureStatusRow(icon: "waveform", title: "Queue transition", status: "Beat boundary")
            FeatureStatusRow(icon: "heart.text.square", title: "Watch workout", status: "Standalone")
            FeatureStatusRow(icon: "applewatch", title: "Apple Watch", status: "HealthKit path")
        }
        .padding(18)
        .beatrunPanelSurface(tint: .teal)
    }

    private func cadencePresetButton(_ value: Int) -> some View {
        Button {
            model.setCadence(value)
        } label: {
            Text("\(value)")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(model.cadence == value ? .accentColor : .secondary)
    }

    private func metricTile(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .beatrunInsetSurface(tint: .blue)
    }

    private func statusChip(icon: String, title: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .beatrunPillSurface(tint: color)
    }

    private func libraryMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .beatrunInsetSurface(tint: .gray)
    }
}

private struct BeatrunSettingsView: View {
    let model: BeatrunModel
    @Binding var languageRawValue: String
    let copy: AppCopy
    let openAppSettings: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(copy("app.language")) {
                    Picker(copy("app.language"), selection: languageSelection) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    Text(copy("language.note"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(copy("library.summary")) {
                    LabeledContent(copy("library"), value: model.musicLibraryState.title)
                    LabeledContent(copy("scanned"), value: "\(model.scannedLibraryTrackCount)")
                    LabeledContent("Retiming", value: "\(model.retimeReadyTrackCount)")
                    LabeledContent("Needs BPM", value: "\(model.tracksNeedingBPMCount)")
                    Button {
                        if model.shouldOpenSettingsForMusicLibrary {
                            openAppSettings()
                        } else {
                            model.requestMusicLibraryAccess()
                        }
                    } label: {
                        Label(copy("library.rescan"), systemImage: "arrow.clockwise")
                    }
                }

                Section(copy("cadence")) {
                    LabeledContent(copy("cadence.target"), value: "\(model.cadence) \(copy("spm"))")
                    Text(copy("beat.rules"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(copy("cadence.range"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(copy("watch.sync")) {
                    LabeledContent(copy("sync"), value: model.watchSyncStatus)
                    Text(copy("watch.sync.note"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(copy("health.watch"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(copy("rights")) {
                    Text(copy("legal.note"))
                        .font(.caption)
                    Text(copy("imported.cc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(copy("about")) {
                    LabeledContent("Beatrun", value: "1.0")
                    Text(copy("competition.mvp"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(copy("settings.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage.preferred(from: languageRawValue) },
            set: { languageRawValue = $0.rawValue }
        )
    }
}

private struct BeatrunRecommendationsView: View {
    let model: BeatrunModel
    let copy: AppCopy

    var body: some View {
        List {
            Section {
                DiscoveryStatusView(
                    phase: model.discoveryPhase,
                    message: model.discoveryMessage,
                    autoMatchMessage: model.autoMatchMessage,
                    searchCount: model.searchCount,
                    matchCount: model.recommendations.count,
                    sourceTitle: model.usingStarterFallback ? "Imported/CC0" : copy("library"),
                    sourceNote: model.usingStarterFallback ? copy("imported.cc") : MusicSource.localLibrary.usageNote,
                    tracksNeedingBPM: model.tracksNeedingBPMCount,
                    metadataOnlyCount: model.metadataOnlyTrackCount,
                    copy: copy
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }

            Section(copy("authorized.tracks")) {
                ForEach(model.recommendations) { match in
                    TrackRow(match: match, isSelected: match.id == model.selectedMatch?.id) {
                        model.select(match)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(copy("recommendations"))
    }
}

private struct BeatrunTempoDetailsView: View {
    let model: BeatrunModel
    let copy: AppCopy

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let selectedMatch = model.nowPlayingMatch {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedMatch.track.title)
                            .font(.title2.bold())
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                        Text("\(selectedMatch.track.artist) • \(selectedMatch.track.genre)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(selectedMatch.matchReason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .beatrunPanelSurface(tint: .blue)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        TempoMetricTile(title: "Target", value: "\(selectedMatch.adjustment.targetCadence)", unit: copy("spm"))
                        TempoMetricTile(title: "Original", value: "\(selectedMatch.adjustment.originalBPM)", unit: "BPM")
                        TempoMetricTile(title: "Adjusted", value: "\(selectedMatch.adjustment.adjustedBPM)", unit: "BPM")
                        TempoMetricTile(title: "Speed", value: selectedMatch.adjustment.speedChangeLabel, unit: "")
                        TempoMetricTile(title: "Score", value: "\(selectedMatch.score)", unit: "%")
                        TempoMetricTile(title: copy("rights"), value: selectedMatch.track.rights.status.title, unit: "")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SyncBar(match: selectedMatch)
                        AlignmentDetails(match: selectedMatch)
                        HStack {
                            Label(selectedMatch.syncLabel, systemImage: "checkmark.seal.fill")
                                .foregroundStyle(abs(selectedMatch.adjustment.speedChangePercent) <= 6 ? .green : .orange)
                            Spacer()
                            Text("Beat \(model.metronome.beatCount)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote.weight(.medium))
                    }
                    .padding(18)
                    .beatrunPanelSurface(tint: .green)
                } else {
                    ContentUnavailableView(
                        copy("no.legal.match"),
                        systemImage: "music.note",
                        description: Text(copy("beat.rules"))
                    )
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(copy("match.details"))
    }
}

private struct TempoMetricTile: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .beatrunInsetSurface(tint: .blue)
    }
}

private struct QueueTransitionView: View {
    let currentMatch: TrackMatch?
    let upcomingMatch: TrackMatch?
    let queueStatus: String
    let transitionStatus: String
    let beatsRemaining: Int
    let isCrossfading: Bool
    let nextTrackReady: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Next track", systemImage: "forward.end.alt.fill")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(isCrossfading ? "Crossfade" : nextTrackReady ? "Preloaded" : "Waiting")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isCrossfading ? .orange : nextTrackReady ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isCrossfading ? Color.orange : nextTrackReady ? Color.green : Color.secondary).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }

            HStack(spacing: 10) {
                queueTrackTile(title: "Current", match: currentMatch)
                queueTrackTile(title: "Next", match: upcomingMatch)
            }

            HStack(spacing: 8) {
                Image(systemName: isCrossfading ? "arrow.left.arrow.right.circle.fill" : "timer")
                    .foregroundStyle(isCrossfading ? .orange : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(transitionStatus)
                        .font(.callout.weight(.semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text("\(beatsRemaining) beats remaining • \(queueStatus)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    (isCrossfading ? Color.orange : Color.blue).opacity(0.15),
                    Color(.tertiarySystemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke((isCrossfading ? Color.orange : Color.blue).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Queue transition, \(transitionStatus), crossfade \(isCrossfading ? "active" : "inactive")")
    }

    private func queueTrackTile(title: String, match: TrackMatch?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(match?.track.title ?? "None")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(match.map { "\($0.adjustment.adjustedBPM) BPM • \($0.adjustment.speedChangeLabel)" } ?? "No legal match")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SyncRuntimeStatus: View {
    let status: String
    let mode: String
    let offsetMilliseconds: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope")
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(status)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("\(mode) tempo match • \(offsetMilliseconds) ms start offset")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback synchronization status, \(status), \(mode) tempo match, \(offsetMilliseconds) milliseconds start offset")
    }
}

private struct AlignmentDetails: View {
    let match: TrackMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tempo Fit", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(Int(match.adjustment.confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Text("1:1 matching only: original BPM is retimed within \(Int(TempoAdjustment.maximumAdjustmentPercent))% to match the target cadence.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(match.track.source.title) • \(match.track.beatGridSource) • \(match.track.rights.status.note)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(match.track.rights.licenseName)
                    .font(.caption.weight(.semibold))
                Text(match.track.rights.attribution)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(match.track.rights.tempoAdjustmentLabel) • \(match.track.analysisLabel) • Source: \(match.track.rights.sourceLink)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            BeatGrid(match: match)

            HStack(spacing: 10) {
                analysisPill("Song beat", "\(match.adjustment.songBeatIntervalMilliseconds) ms")
                analysisPill("Runner beat", "\(match.adjustment.metronomeIntervalMilliseconds) ms")
                analysisPill("Speed", match.adjustment.speedChangeLabel)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func analysisPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BeatGrid: View {
    let match: TrackMatch

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemGroupedBackground))

                ForEach(0..<8, id: \.self) { index in
                    let x = proxy.size.width * CGFloat(index) / 7
                    beatMarker(x: x, color: .blue, height: 24)
                }

                ForEach(0..<8, id: \.self) { index in
                    let phase = CGFloat(match.adjustment.phaseOffsetMilliseconds) / 140
                    let rawX = proxy.size.width * (CGFloat(index) / 7 + phase / 7)
                    let wrappedX = rawX.truncatingRemainder(dividingBy: max(1, proxy.size.width))
                    beatMarker(x: wrappedX, color: .green, height: 16)
                }
            }
        }
        .frame(height: 28)
        .accessibilityLabel("1 to 1 tempo sync grid")
    }

    private func beatMarker(x: CGFloat, color: Color, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color.opacity(0.8))
            .frame(width: 3, height: height)
            .offset(x: x)
    }
}

private struct DiscoveryStatusView: View {
    let phase: DiscoveryPhase
    let message: String
    let autoMatchMessage: String
    let searchCount: Int
    let matchCount: Int
    let sourceTitle: String
    let sourceNote: String
    let tracksNeedingBPM: Int
    let metadataOnlyCount: Int
    let copy: AppCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: phase.systemImage)
                    .foregroundStyle(statusColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(phase.title)
                        .font(.subheadline.weight(.semibold))

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Label(autoMatchMessage, systemImage: "arrow.triangle.2.circlepath")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 10) {
                statusPill(title: copy("source"), value: sourceTitle)
                statusPill(title: copy("matches"), value: "\(matchCount)")
                statusPill(title: "BPM", value: "\(tracksNeedingBPM)")
            }

            Text("\(sourceNote) Metadata-only tracks: \(metadataOnlyCount). Searches: \(searchCount).")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusColor: Color {
        switch phase {
        case .ready:
            .green
        case .searching, .analyzing:
            .blue
        case .failed:
            .red
        }
    }

    private func statusPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TrackRow: View {
    let match: TrackMatch
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "music.note")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(match.track.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("\(match.track.artist) • \(match.track.genre)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        rowPill("\(match.adjustment.originalBPM) -> \(match.adjustment.adjustedBPM) BPM", color: .blue)
                        rowPill(match.adjustment.speedChangeLabel, color: abs(match.adjustment.speedChangePercent) <= 6 ? .green : .orange)
                        rowPill(match.track.source.title, color: .purple)
                        rowPill(match.track.playbackCapabilityLabel, color: match.track.canUseForTempoAdjustedPlayback ? .green : .gray)
                    }

                    Text("\(match.matchReason) • \(match.track.analysisLabel)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(match.score)%")
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    Text(match.syncLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func rowPill(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.11))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct SyncBar: View {
    let match: TrackMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tempo fit")
                Spacer()
                Text(match.adjustment.speedChangeLabel)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))

                    Capsule()
                        .fill(abs(match.adjustment.speedChangePercent) <= 6 ? Color.green : Color.orange)
                        .frame(width: max(10, proxy.size.width * CGFloat(match.score) / 100))

                    ForEach(0..<8, id: \.self) { index in
                        let x = proxy.size.width * CGFloat(index) / 7
                        Rectangle()
                            .fill(Color.white.opacity(0.65))
                            .frame(width: 2)
                            .offset(x: x)
                    }
                }
            }
            .frame(height: 14)
        }
    }
}

private struct FeatureStatusRow: View {
    let icon: String
    let title: String
    let status: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(status)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct BeatrunPanelSurface: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(tint.opacity(0.08)), in: .rect(cornerRadius: 8))
                .shadow(color: tint.opacity(0.12), radius: 18, y: 8)
        } else {
            content
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
        }
    }
}

private struct BeatrunInsetSurface: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(tint.opacity(0.07)), in: .rect(cornerRadius: 8))
        } else {
            content
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct BeatrunPillSurface: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(tint.opacity(0.12)).interactive(), in: .rect(cornerRadius: 8))
        } else {
            content
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private extension View {
    func beatrunPanelSurface(tint: Color) -> some View {
        modifier(BeatrunPanelSurface(tint: tint))
    }

    func beatrunInsetSurface(tint: Color) -> some View {
        modifier(BeatrunInsetSurface(tint: tint))
    }

    func beatrunPillSurface(tint: Color) -> some View {
        modifier(BeatrunPillSurface(tint: tint))
    }
}

#Preview {
    ContentView()
}
