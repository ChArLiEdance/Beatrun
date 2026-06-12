import SwiftUI

struct WatchContentView: View {
    @State private var state = WatchPlaybackState()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                cadenceHeader
                playbackStatus
                trackQueue
                controlButton
            }
            .padding(.vertical, 8)
        }
        .containerBackground(.black, for: .navigation)
    }

    private var cadenceHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Beatrun")
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(state.targetCadence)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("SPM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var playbackStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(state.syncStatus, systemImage: state.isPlaying ? "waveform" : "pause.circle")
                .font(.caption)
                .lineLimit(2)

            Text(state.transitionStatus)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(state.crossfadeStatus)
                .font(.caption2)
                .foregroundStyle(state.isPlaying ? .orange : .secondary)
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var trackQueue: some View {
        VStack(alignment: .leading, spacing: 6) {
            queueRow(title: "Now", value: state.currentTrack)
            queueRow(title: "Next", value: state.nextTrack)
        }
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
            Spacer()
        }
    }

    private var controlButton: some View {
        Button {
            state.togglePlayback()
        } label: {
            Label(state.isPlaying ? "Pause" : "Play", systemImage: state.isPlaying ? "pause.fill" : "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    WatchContentView()
}
