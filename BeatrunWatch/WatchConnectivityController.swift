import Foundation
@preconcurrency import WatchConnectivity

final class WatchConnectivityController: NSObject, WCSessionDelegate {
    private var session: WCSession?

    var onPayload: (@MainActor @Sendable (WatchSyncPayload) -> Void)?
    var onStatusChange: (@MainActor @Sendable (String) -> Void)?

    override init() {
        super.init()
        activateSession()
    }

    func send(_ command: WatchControlMessage) {
        guard let session, session.activationState == .activated else {
            setStatus("iPhone sync activating")
            return
        }

        guard session.isReachable else {
            setStatus("iPhone not reachable")
            return
        }

        session.sendMessage(command.dictionary, replyHandler: nil) { [weak self] _ in
            self?.setStatus("Control queued")
        }
    }

    private func activateSession() {
        guard WCSession.isSupported() else {
            setStatus("iPhone sync unavailable")
            return
        }

        let defaultSession = WCSession.default
        session = defaultSession
        defaultSession.delegate = self
        defaultSession.activate()
    }

    private func setStatus(_ status: String) {
        let callback = onStatusChange
        Task { @MainActor in
            callback?(status)
        }
    }

    private func applyPayload(from dictionary: [String: Any]) {
        guard let payload = WatchSyncPayload(dictionary: dictionary) else { return }
        let callback = onPayload
        Task { @MainActor in
            callback?(payload)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if error != nil {
            setStatus("iPhone sync unavailable")
        } else if activationState == .activated {
            setStatus(session.isReachable ? "iPhone connected" : "Waiting for iPhone")
        } else {
            setStatus("iPhone sync inactive")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        setStatus(session.isReachable ? "iPhone connected" : "Waiting for iPhone")
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyPayload(from: applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard
            let kind = message["kind"] as? String,
            kind == "state",
            let payload = message["payload"] as? [String: Any]
        else {
            return
        }

        applyPayload(from: payload)
    }
}
