import Foundation
@preconcurrency import WatchConnectivity

final class WatchSyncCoordinator: NSObject, WCSessionDelegate {
    private var session: WCSession?

    private(set) var connectionStatus = "Watch sync starting"
    var onCommand: (@MainActor @Sendable (WatchControlMessage) -> Void)?
    var onStatusChange: (@MainActor @Sendable (String) -> Void)?

    override init() {
        super.init()
        activateSession()
    }

    func publish(_ payload: WatchSyncPayload) {
        guard let session else {
            setStatus("Watch sync unavailable")
            return
        }

        guard session.activationState == .activated else {
            setStatus("Watch sync activating")
            return
        }

        do {
            try session.updateApplicationContext(payload.dictionary)
            setStatus(session.isReachable ? "Watch connected" : "Watch updated in background")
        } catch {
            setStatus("Watch sync delayed")
        }

        guard session.isReachable else { return }
        session.sendMessage(
            ["kind": "state", "payload": payload.dictionary],
            replyHandler: nil
        ) { [weak self] _ in
            self?.setStatus("Watch update queued")
        }
    }

    private func activateSession() {
        guard WCSession.isSupported() else {
            setStatus("Watch sync unavailable")
            return
        }

        let defaultSession = WCSession.default
        session = defaultSession
        defaultSession.delegate = self
        defaultSession.activate()
    }

    private func setStatus(_ status: String) {
        connectionStatus = status
        let callback = onStatusChange
        Task { @MainActor in
            callback?(status)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if error != nil {
            setStatus("Watch sync unavailable")
        } else if activationState == .activated {
            setStatus(session.isReachable ? "Watch connected" : "Watch ready")
        } else {
            setStatus("Watch sync inactive")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        setStatus(session.isReachable ? "Watch connected" : "Watch updated in background")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let command = WatchControlMessage(dictionary: message) else { return }
        let callback = onCommand
        Task { @MainActor in
            callback?(command)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        setStatus("Watch sync inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
