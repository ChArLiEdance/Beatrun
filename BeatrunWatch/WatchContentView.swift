import SwiftUI

struct WatchContentView: View {
    @State private var state = WatchPlaybackState()
    @State private var workout = WatchWorkoutManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                cadenceHeader
                workoutControls
                cadenceControls
                workoutStatus
                playbackStatus
                trackQueue
                tempoSummary
                connectionStatus
            }
            .padding(.vertical, 8)
        }
        .containerBackground(.black, for: .navigation)
        .task {
#if DEBUG
            if CommandLine.arguments.contains("-BeatrunWatchDemoWorkout") {
                try? await Task.sleep(for: .milliseconds(500))
                state.startWorkout()
                workout.startDemoFallback(targetCadence: state.targetCadence)
            }
#endif
        }
    }

    private var cadenceHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Beatrun")
                    .font(.headline)
                Spacer()
                Image(systemName: workout.state == .running ? "figure.run.circle.fill" : "figure.run.circle")
                    .foregroundStyle(workout.state == .running ? .green : .secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(state.targetCadence)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("SPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(workout.state.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(workout.state == .running ? .green : .secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                Label(workout.currentCadence == 0 ? "-- current" : "\(workout.currentCadence) current", systemImage: "figure.run")
                Text(workout.cadenceDeltaLabel)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
    }

    private var workoutStatus: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(workout.elapsedLabel, systemImage: "timer")
                    .foregroundStyle(.blue)
                Spacer()
                Text(workout.metronomeRunning ? "Metronome on" : "Metronome ready")
                    .foregroundStyle(workout.metronomeRunning ? .green : .secondary)
            }
            .font(.caption2.weight(.medium))

            HStack(spacing: 8) {
                compactMetric("HR", workout.heartRateLabel)
                compactMetric("Energy", workout.energyLabel)
                compactMetric("Dist", workout.distanceLabel)
            }

            Text(workout.authorizationStatus)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var workoutControls: some View {
        HStack(spacing: 8) {
            if workout.state == .running || workout.state == .paused {
                Button {
                    let shouldRunAfterTap = workout.state == .paused
                    workout.pauseOrResume()
                    state.pauseOrResumeWorkout(isRunning: shouldRunAfterTap)
                } label: {
                    Label(workout.state == .running ? "Pause" : "Resume", systemImage: workout.state == .running ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    workout.end()
                    state.endWorkout()
                } label: {
                    Label("End", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    state.startWorkout()
                    workout.start(targetCadence: state.targetCadence)
                } label: {
                    Label("Start Workout", systemImage: "figure.run")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .controlSize(.small)
    }

    private var cadenceControls: some View {
        HStack(spacing: 8) {
            Button {
                state.adjustCadence(by: -5)
                workout.updateTargetCadence(state.targetCadence)
            } label: {
                Label("-5", systemImage: "minus")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }

            Button {
                state.adjustCadence(by: 5)
                workout.updateTargetCadence(state.targetCadence)
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

    private var connectionStatus: some View {
        HStack {
            Image(systemName: state.connectionStatus == "iPhone connected" ? "iphone.and.arrow.forward" : "applewatch")
            Text(state.standaloneStatus)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    WatchContentView()
}
