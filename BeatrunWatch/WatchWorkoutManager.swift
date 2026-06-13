import CoreMotion
import Foundation
@preconcurrency import HealthKit
import Observation

enum WatchWorkoutState: String {
    case idle
    case requestingPermission
    case running
    case paused
    case ended
    case unavailable

    var title: String {
        switch self {
        case .idle:
            "Standalone"
        case .requestingPermission:
            "Health"
        case .running:
            "Running"
        case .paused:
            "Paused"
        case .ended:
            "Ended"
        case .unavailable:
            "Fallback"
        }
    }
}

@Observable
@MainActor
final class WatchWorkoutManager: NSObject {
    var state: WatchWorkoutState = .idle
    var authorizationStatus = "Health permission not requested"
    var elapsedSeconds = 0
    var currentCadence = 0
    var heartRate: Double?
    var activeEnergy: Double?
    var distanceMeters: Double?
    var metronomeRunning = false
    var lastError: String?

    @ObservationIgnored private let healthStore = HKHealthStore()
    @ObservationIgnored private let pedometer = CMPedometer()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var targetCadence = 180

    var elapsedLabel: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var cadenceDelta: Int {
        currentCadence == 0 ? 0 : currentCadence - targetCadence
    }

    var cadenceDeltaLabel: String {
        guard currentCadence > 0 else { return "No live cadence" }
        let sign = cadenceDelta >= 0 ? "+" : ""
        return "\(sign)\(cadenceDelta) vs target"
    }

    var heartRateLabel: String {
        heartRate.map { "\(Int($0.rounded())) bpm" } ?? "-- bpm"
    }

    var energyLabel: String {
        activeEnergy.map { "\(Int($0.rounded())) kcal" } ?? "-- kcal"
    }

    var distanceLabel: String {
        guard let distanceMeters else { return "-- km" }
        return String(format: "%.2f km", distanceMeters / 1_000)
    }

    func start(targetCadence: Int) {
        self.targetCadence = targetCadence
        state = .requestingPermission
        metronomeRunning = false
        lastError = nil

        Task {
            await requestAuthorizationIfNeeded()
            guard state != .unavailable else {
                startLocalFallback()
                return
            }
            startWorkoutSession()
        }
    }

#if DEBUG
    func startDemoFallback(targetCadence: Int) {
        self.targetCadence = targetCadence
        authorizationStatus = "Simulator fallback metrics"
        lastError = nil
        startLocalFallback()
    }
#endif

    func updateTargetCadence(_ targetCadence: Int) {
        self.targetCadence = targetCadence
    }

    func pauseOrResume() {
        switch state {
        case .running:
            pause()
        case .paused:
            resume()
        default:
            break
        }
    }

    func end() {
        session?.end()
        finishBuilder()
        stopLocalSensors()
        state = .ended
        metronomeRunning = false
        authorizationStatus = "Workout ended"
    }

    private func requestAuthorizationIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            state = .unavailable
            authorizationStatus = "HealthKit unavailable; simulator fallback active"
            return
        }

        let readTypes = workoutReadTypes()
        let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]

        await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] success, error in
                Task { @MainActor in
                    if success {
                        self?.authorizationStatus = "HealthKit authorized"
                    } else {
                        self?.state = .unavailable
                        self?.authorizationStatus = error?.localizedDescription ?? "Health permission unavailable; using local fallback"
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder

            let startDate = Date()
            startedAt = startDate
            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { [weak self] success, error in
                Task { @MainActor in
                    if !success {
                        self?.lastError = error?.localizedDescription
                    }
                }
            }

            state = .running
            metronomeRunning = true
            startElapsedTimer()
            startCadenceUpdates()
        } catch {
            lastError = error.localizedDescription
            state = .unavailable
            authorizationStatus = "Workout session unavailable; using simulator fallback"
            startLocalFallback()
        }
    }

    private func startLocalFallback() {
        if state != .paused {
            elapsedSeconds = 0
            startedAt = Date()
        }
        state = .running
        metronomeRunning = true
        if currentCadence == 0 {
            currentCadence = targetCadence
        }
        startElapsedTimer()
        startCadenceUpdates()
    }

    private func pause() {
        session?.pause()
        state = .paused
        metronomeRunning = false
        stopTimer()
        pedometer.stopUpdates()
    }

    private func resume() {
        session?.resume()
        state = .running
        metronomeRunning = true
        startedAt = Date().addingTimeInterval(TimeInterval(-elapsedSeconds))
        startElapsedTimer()
        startCadenceUpdates()
    }

    private func startElapsedTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        if let startedAt {
            elapsedSeconds = max(0, Int(Date().timeIntervalSince(startedAt).rounded(.down)))
        } else {
            elapsedSeconds += 1
        }

        if currentCadence == 0 || state == .unavailable || authorizationStatus.contains("fallback") {
            let drift = Int((sin(Double(elapsedSeconds) / 6.0) * 3.0).rounded())
            currentCadence = targetCadence + drift
        }
    }

    private func startCadenceUpdates() {
        guard CMPedometer.isCadenceAvailable() else {
            currentCadence = targetCadence
            return
        }

        pedometer.startUpdates(from: Date()) { [weak self] data, _ in
            guard let cadence = data?.currentCadence?.doubleValue else { return }
            Task { @MainActor in
                self?.currentCadence = max(0, Int((cadence * 60.0).rounded()))
            }
        }
    }

    private func stopLocalSensors() {
        stopTimer()
        pedometer.stopUpdates()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func finishBuilder() {
        guard let builder else { return }
        let endDate = Date()
        builder.endCollection(withEnd: endDate) { [weak self] _, _ in
            builder.finishWorkout { _, error in
                Task { @MainActor in
                    self?.lastError = error?.localizedDescription
                }
            }
        }
    }

    private func workoutReadTypes() -> Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        return types
    }

    private func updateStatistics(for identifiers: [String]) {
        guard let builder else { return }

        for identifier in identifiers {
            switch identifier {
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                updateHeartRate(from: builder)
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                updateEnergy(from: builder)
            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                updateDistance(from: builder)
            default:
                break
            }
        }
    }

    private func updateHeartRate(from builder: HKLiveWorkoutBuilder) {
        guard
            let type = HKObjectType.quantityType(forIdentifier: .heartRate),
            let value = builder.statistics(for: type)?.mostRecentQuantity()
        else { return }

        heartRate = value.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
    }

    private func updateEnergy(from builder: HKLiveWorkoutBuilder) {
        guard
            let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let value = builder.statistics(for: type)?.sumQuantity()
        else { return }

        activeEnergy = value.doubleValue(for: .kilocalorie())
    }

    private func updateDistance(from builder: HKLiveWorkoutBuilder) {
        guard
            let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let value = builder.statistics(for: type)?.sumQuantity()
        else { return }

        distanceMeters = value.doubleValue(for: .meter())
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor [weak self] in
            switch toState {
            case .running:
                self?.state = .running
                self?.metronomeRunning = true
            case .paused:
                self?.state = .paused
                self?.metronomeRunning = false
            case .ended:
                self?.state = .ended
                self?.metronomeRunning = false
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.lastError = error.localizedDescription
            self?.state = .unavailable
            self?.authorizationStatus = "Workout session failed; local fallback available"
        }
    }
}

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let identifiers = collectedTypes.compactMap { sampleType -> String? in
            (sampleType as? HKQuantityType)?.identifier
        }

        Task { @MainActor [weak self, identifiers] in
            self?.updateStatistics(for: identifiers)
        }
    }
}
