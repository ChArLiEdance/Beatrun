import Foundation
import Observation

@MainActor
@Observable
final class MetronomeEngine {
    var cadence: Int = 180 {
        didSet {
            guard cadence != oldValue, isRunning else { return }
            restartTimer()
        }
    }

    private(set) var isRunning = false
    private(set) var beatCount = 0
    private(set) var lastBeatDate: Date?

    @ObservationIgnored private var timer: Timer?

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        beatCount = 0
        playClick()
        restartTimer()
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = 60.0 / Double(cadence)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playClick()
            }
        }
    }

    private func playClick() {
        beatCount += 1
        lastBeatDate = Date()
    }
}
