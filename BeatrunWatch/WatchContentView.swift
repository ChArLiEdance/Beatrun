import SwiftUI

struct WatchContentView: View {
    @State private var state = WatchPlaybackState()
    @State private var workout = WatchWorkoutManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                WatchCadenceHero(
                    targetCadence: state.targetCadence,
                    workoutState: workout.state,
                    currentCadence: workout.currentCadence,
                    cadenceDeltaLabel: workout.cadenceDeltaLabel,
                    elapsedLabel: workout.elapsedLabel
                )

                WatchWorkoutControls(
                    workoutState: workout.state,
                    start: startWorkout,
                    pauseOrResume: pauseOrResumeWorkout,
                    end: endWorkout
                )

                WatchCadenceControls(
                    decrease: { adjustCadence(by: -5) },
                    increase: { adjustCadence(by: 5) }
                )

                WatchMetricsPanel(
                    metronomeRunning: workout.metronomeRunning,
                    heartRate: workout.heartRateLabel,
                    energy: workout.energyLabel,
                    distance: workout.distanceLabel,
                    authorizationStatus: workout.authorizationStatus
                )

                WatchPlaybackPanel(
                    beatsRemaining: state.beatsRemaining,
                    crossfadeStatus: state.crossfadeStatus,
                    syncStatus: state.syncStatus,
                    transitionStatus: state.transitionStatus,
                    isPlaying: state.isPlaying,
                    isCrossfading: state.isCrossfading
                )

                WatchQueuePanel(
                    currentTrack: state.currentTrack,
                    nextTrack: state.nextTrack,
                    adjustedBPM: state.adjustedBPM,
                    speedChangeLabel: state.speedChangeLabel,
                    beatCount: state.beatCount
                )

                WatchConnectionFooter(
                    connectionStatus: state.connectionStatus,
                    standaloneStatus: state.standaloneStatus
                )
            }
            .padding(.vertical, 6)
        }
        .containerBackground(.black, for: .navigation)
        .task {
            await runDebugLaunchHooks()
        }
    }

    private func startWorkout() {
        state.startWorkout()
        workout.start(targetCadence: state.targetCadence)
    }

    private func pauseOrResumeWorkout() {
        let shouldRunAfterTap = workout.state == .paused
        workout.pauseOrResume()
        state.pauseOrResumeWorkout(isRunning: shouldRunAfterTap)
    }

    private func endWorkout() {
        workout.end()
        state.endWorkout()
    }

    private func adjustCadence(by delta: Int) {
        state.adjustCadence(by: delta)
        workout.updateTargetCadence(state.targetCadence)
    }

    private func runDebugLaunchHooks() async {
#if DEBUG
        if CommandLine.arguments.contains("-BeatrunWatchDemoWorkout") {
            try? await Task.sleep(for: .milliseconds(500))
            state.startWorkout()
            workout.startDemoFallback(targetCadence: state.targetCadence)
        }
#endif
    }
}

private struct WatchCadenceHero: View {
    let targetCadence: Int
    let workoutState: WatchWorkoutState
    let currentCadence: Int
    let cadenceDeltaLabel: String
    let elapsedLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text("Beatrun")
                    .font(.headline)

                Spacer()

                Label(workoutState.title, systemImage: workoutState == .running ? "figure.run.circle.fill" : "figure.run.circle")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(workoutState == .running ? .green : .secondary)
                    .accessibilityLabel(workoutState.title)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(targetCadence)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.82)

                Text("SPM")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 4)

                Text(workoutState.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(workoutState == .running ? .green : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            HStack(spacing: 8) {
                Label(currentCadence == 0 ? "--" : "\(currentCadence)", systemImage: "figure.run")
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(cadenceDeltaLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Text(elapsedLabel)
                    .monospacedDigit()
                    .foregroundStyle(.blue)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .watchCardSurface(prominence: workoutState == .running ? .active : .regular)
    }
}

private struct WatchWorkoutControls: View {
    let workoutState: WatchWorkoutState
    let start: () -> Void
    let pauseOrResume: () -> Void
    let end: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if workoutState == .running || workoutState == .paused {
                Button(action: pauseOrResume) {
                    Label(workoutState == .running ? "Pause" : "Resume", systemImage: workoutState == .running ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive, action: end) {
                    Label("End", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: start) {
                    Label("Start Workout", systemImage: "figure.run")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .controlSize(.small)
    }
}

private struct WatchCadenceControls: View {
    let decrease: () -> Void
    let increase: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: decrease) {
                Label("-5", systemImage: "minus")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }

            Button(action: increase) {
                Label("+5", systemImage: "plus")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

private struct WatchMetricsPanel: View {
    let metronomeRunning: Bool
    let heartRate: String
    let energy: String
    let distance: String
    let authorizationStatus: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(metronomeRunning ? "Metronome on" : "Metronome ready", systemImage: "metronome")
                    .foregroundStyle(metronomeRunning ? .green : .secondary)
                Spacer()
            }
            .font(.caption2.weight(.semibold))

            HStack(spacing: 8) {
                WatchMetric(title: "HR", value: heartRate)
                WatchMetric(title: "Energy", value: energy)
                WatchMetric(title: "Dist", value: distance)
            }

            Text(authorizationStatus)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .watchCardSurface()
    }
}

private struct WatchPlaybackPanel: View {
    let beatsRemaining: Int
    let crossfadeStatus: String
    let syncStatus: String
    let transitionStatus: String
    let isPlaying: Bool
    let isCrossfading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("\(beatsRemaining) beats", systemImage: "timer")
                    .foregroundStyle(.blue)
                Spacer()
                Text(crossfadeStatus)
                    .foregroundStyle(isCrossfading ? .orange : .secondary)
            }
            .font(.caption2.weight(.semibold))

            Label(syncStatus, systemImage: isPlaying ? "waveform.path" : "scope")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(transitionStatus)
                .font(.caption2)
                .foregroundStyle(isCrossfading ? .orange : .secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .watchCardSurface()
    }
}

private struct WatchQueuePanel: View {
    let currentTrack: String
    let nextTrack: String
    let adjustedBPM: Int
    let speedChangeLabel: String
    let beatCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            queueRow(title: "Now", value: currentTrack)
            queueRow(title: "Next", value: nextTrack)

            HStack(spacing: 6) {
                WatchMetric(title: "BPM", value: "\(adjustedBPM)")
                WatchMetric(title: "Shift", value: speedChangeLabel)
                WatchMetric(title: "Beat", value: "\(beatCount)")
            }
        }
        .watchCardSurface()
    }

    private func queueRow(title: String, value: String) -> some View {
        HStack(spacing: 7) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)

            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Spacer(minLength: 0)
        }
    }
}

private struct WatchConnectionFooter: View {
    let connectionStatus: String
    let standaloneStatus: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: connectionStatus == "iPhone connected" ? "iphone.and.arrow.forward" : "applewatch")
            Text(standaloneStatus)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }
}

private struct WatchMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum WatchCardProminence {
    case regular
    case active
}

private struct WatchCardSurface: ViewModifier {
    let prominence: WatchCardProminence

    func body(content: Content) -> some View {
        content
            .padding(9)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(prominence == .active ? Color.green.opacity(0.12) : Color.white.opacity(0.03))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(prominence == .active ? Color.green.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private extension View {
    func watchCardSurface(prominence: WatchCardProminence = .regular) -> some View {
        modifier(WatchCardSurface(prominence: prominence))
    }
}

#Preview {
    WatchContentView()
}
