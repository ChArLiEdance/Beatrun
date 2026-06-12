import SwiftUI

struct ContentView: View {
    @State private var model = BeatrunModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    dashboardHeader
                    cadencePanel
                    nowPlayingPanel
                    recommendationsPanel
                    roadmapPanel
                }
                .padding(16)
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
        }
        .task {
            model.discoverMusic()
#if DEBUG
            if CommandLine.arguments.contains("-BeatrunDemoAutoplay") {
                try? await Task.sleep(for: .milliseconds(700))
                model.startPlayback()
            }
#endif
        }
    }

    private var dashboardHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Run mix")
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                Text("Cadence-locked demo audio")
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
                    Text("Target Cadence")
                        .font(.headline)
                    Text("Steps per minute")
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
                statusChip(icon: "music.note", title: "Offline audio", color: .orange)
            }

            Slider(
                value: Binding(
                    get: { Double(model.cadence) },
                    set: { model.setCadence(Int($0.rounded())) }
                ),
                in: 140...200,
                step: 1
            )
            .accessibilityLabel("Target cadence")

            HStack {
                cadencePresetButton(160)
                cadencePresetButton(170)
                cadencePresetButton(180)
                cadencePresetButton(190)
            }

            Picker(
                "Music Type",
                selection: Binding(
                    get: { model.vocalPreference },
                    set: { model.setVocalPreference($0) }
                )
            ) {
                ForEach(VocalPreference.allCases) { preference in
                    Text(preference.title).tag(preference)
                }
            }
            .pickerStyle(.segmented)

            Text(model.vocalPreference.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }

    private var nowPlayingPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Now Playing", systemImage: model.metronome.isRunning ? "waveform.path.ecg" : "waveform.path")
                        .font(.headline)

                    Text(model.nowPlayingMatch?.track.title ?? "No legal match")
                        .font(.title2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(model.nowPlayingMatch.map { "\($0.adjustment.originalBPM) -> \($0.adjustment.adjustedBPM) BPM • \($0.adjustment.speedChangeLabel)" } ?? "Choose a legal 1:1 demo track")
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

                    Text("Music \(Int(model.metronome.musicVolume * 100))%")
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
                .accessibilityLabel("Backing music volume")

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
                .accessibilityLabel("Metronome click volume")

                Text("Offline demo loop for \(model.metronome.selectedTrackTitle)")
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
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if let selectedMatch = model.nowPlayingMatch {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(selectedMatch.track.artist) • \(selectedMatch.track.genre)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(selectedMatch.matchReason)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metricTile(title: "Target", value: "\(selectedMatch.adjustment.targetCadence)", unit: "SPM")
                        metricTile(title: "Original", value: "\(selectedMatch.adjustment.originalBPM)", unit: "BPM")
                        metricTile(title: "Adjusted", value: "\(selectedMatch.adjustment.adjustedBPM)", unit: "BPM")
                        metricTile(title: "Speed", value: selectedMatch.adjustment.speedChangeLabel, unit: "")
                        metricTile(title: "Score", value: "\(selectedMatch.score)", unit: "%")
                        metricTile(title: "Rights", value: selectedMatch.track.rights.status.title, unit: "")
                    }

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
            }
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }

    private var recommendationsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended Safe Tracks")
                        .font(.headline)

                    Text("Legal 1:1 fits for \(model.cadence) SPM")
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
                .accessibilityLabel("Search again")
            }

            DiscoveryStatusView(
                phase: model.discoveryPhase,
                message: model.discoveryMessage,
                autoMatchMessage: model.autoMatchMessage,
                searchCount: model.searchCount,
                matchCount: model.recommendations.count
            )

            if model.discoveryPhase == .searching || model.discoveryPhase == .analyzing {
                ProgressView()
            }

            ForEach(model.recommendations) { match in
                TrackRow(
                    match: match,
                    isSelected: match.id == model.selectedMatch?.id
                ) {
                    model.select(match)
                }
            }
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
    }

    private var roadmapPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Competition MVP")
                .font(.headline)

            FeatureStatusRow(icon: "music.note.list", title: "Music matching", status: "Offline catalog")
            FeatureStatusRow(icon: "metronome", title: "Metronome", status: "Audio click")
            FeatureStatusRow(icon: "waveform", title: "Queue transition", status: "Beat boundary")
            FeatureStatusRow(icon: "applewatch", title: "Apple Watch", status: "Sync-ready")
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func statusChip(icon: String, title: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

            Text("\(match.track.beatGridSource) • \(match.track.rights.status.note)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(match.track.rights.licenseName)
                    .font(.caption.weight(.semibold))
                Text(match.track.rights.attribution)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(match.track.rights.tempoAdjustmentLabel) • Source: \(match.track.rights.sourceLink)")
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
                statusPill(title: "Source", value: MusicSource.generatedPreview.title)
                statusPill(title: "Matches", value: "\(matchCount)")
                statusPill(title: "Searches", value: "\(searchCount)")
            }

            Text(MusicSource.generatedPreview.usageNote)
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
                        rowPill(match.track.rights.status.title, color: .gray)
                    }

                    Text(match.matchReason)
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

#Preview {
    ContentView()
}
