import SwiftUI

struct ContentView: View {
    @State private var model = BeatrunModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    cadencePanel
                    nowPlayingPanel
                    recommendationsPanel
                    roadmapPanel
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Beatrun")
        }
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
    }

    private var nowPlayingPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Sync Preview", systemImage: "waveform.path")
                    .font(.headline)

                Spacer()

                Button {
                    model.metronome.toggle()
                } label: {
                    Image(systemName: model.metronome.isRunning ? "pause.fill" : "play.fill")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .accessibilityLabel(model.metronome.isRunning ? "Stop metronome" : "Start metronome")
            }

            if let selectedMatch = model.selectedMatch {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedMatch.track.title)
                        .font(.title2.bold())

                    Text("\(selectedMatch.track.artist) • \(selectedMatch.track.genre)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        metricTile(title: "Track", value: "\(selectedMatch.track.bpm)", unit: "BPM")
                        metricTile(title: "Match", value: "\(selectedMatch.score)", unit: "%")
                        metricTile(title: "Offset", value: "\(selectedMatch.offsetMilliseconds)", unit: "ms")
                    }

                    SyncBar(match: selectedMatch)

                    HStack {
                        Label(selectedMatch.syncLabel, systemImage: "checkmark.seal.fill")
                            .foregroundStyle(selectedMatch.tempoDistance <= 6 ? .green : .orange)

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
    }

    private var recommendationsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommended Tracks")
                    .font(.headline)

                Spacer()

                Text("\(model.recommendations.count) matches")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
    }

    private var roadmapPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prototype Scope")
                .font(.headline)

            FeatureStatusRow(icon: "music.note.list", title: "Music discovery", status: "Mock catalog")
            FeatureStatusRow(icon: "metronome", title: "Metronome", status: "Local click")
            FeatureStatusRow(icon: "waveform", title: "Beat alignment", status: "Simulated score")
            FeatureStatusRow(icon: "applewatch", title: "Apple Watch", status: "Future phase")
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

                    Text("\(match.track.artist) • \(match.track.bpm) BPM • \(match.track.genre)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SyncBar: View {
    let match: TrackMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Beat alignment")
                Spacer()
                Text("\(match.tempoDistance) BPM delta")
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))

                    Capsule()
                        .fill(match.tempoDistance <= 6 ? Color.green : Color.orange)
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
