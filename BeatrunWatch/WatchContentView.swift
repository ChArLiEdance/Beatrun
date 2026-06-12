import SwiftUI

struct WatchContentView: View {
    @State private var state = WatchPlaybackState()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                cadenceHeader
                trackQueue
                playbackStatus
                cadenceControls
                tempoSummary
                playbackControls
            }
            .padding(.vertical, 8)
        }
        .containerBackground(.black, for: .navigation)
    }

    private var cadenceHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Beatrun")
                    .font(.headline)
                Spacer()
                Image(systemName: state.isPlaying ? "figure.run.circle.fill" : "figure.run.circle")
                    .foregroundStyle(state.isPlaying ? .green : .secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(state.targetCadence)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("SPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(state.playbackStatus)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(state.isPlaying ? .green : .secondary)
                    .lineLimit(1)
            }
        }
    }

    private var cadenceControls: some View {
        HStack(spacing: 8) {
            Button {
                state.adjustCadence(by: -5)
            } label: {
                Label("-5", systemImage: "minus")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }

            Button {
                state.adjustCadence(by: 5)
            } label: {
                Label("+5", systemImage: "plus")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var playbackStatus: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("\(state.beatsRemaining) beats", systemImage: "timer")
                    .foregroundStyle(.blue)
                Spacer()
                Text(state.crossfadeStatus)
                    .foregroundStyle(state.isCrossfading ? .orange : .secondary)
            }
            .font(.caption2.weight(.medium))

            Label(state.syncStatus, systemImage: state.isPlaying ? "waveform.path" : "scope")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(state.transitionStatus)
                .font(.caption2)
                .foregroundStyle(state.isCrossfading ? .orange : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var trackQueue: some View {
        VStack(alignment: .leading, spacing: 6) {
            queueRow(title: "Now", value: state.currentTrack)
            queueRow(title: "Next", value: state.nextTrack)
        }
        .padding(.vertical, 2)
    }

    private func queueRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer()
        }
    }

    private var tempoSummary: some View {
        HStack(spacing: 6) {
            compactMetric("BPM", "\(state.adjustedBPM)")
            compactMetric("Shift", state.speedChangeLabel)
            compactMetric("Beat", "\(state.beatCount)")
        }
    }

    private func compactMetric(_ title: String, _ value: String) -> some View {
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

    private var playbackControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    state.togglePlayback()
                } label: {
                    Label(state.playPauseTitle, systemImage: state.playPauseSymbol)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    state.stopPlayback()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                Text(state.connectionStatus)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WatchContentView()
}
