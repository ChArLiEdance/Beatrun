import Foundation

struct WatchSyncPayload: Codable, Hashable, Sendable {
    var targetCadence: Int
    var isPlaying: Bool
    var playbackStatus: String
    var syncStatus: String
    var currentTrack: String
    var nextTrack: String
    var transitionStatus: String
    var beatsRemaining: Int
    var isCrossfading: Bool
    var beatCount: Int
    var originalBPM: Int
    var adjustedBPM: Int
    var speedChangeLabel: String
    var rightsStatus: String
    var updatedAt: Date

    static let fallback = WatchSyncPayload(
        targetCadence: 180,
        isPlaying: false,
        playbackStatus: "Ready",
        syncStatus: "1:1 tempo match ready",
        currentTrack: "Clean Stride",
        nextTrack: "Blue Relay",
        transitionStatus: "Next track synced in 4 beats",
        beatsRemaining: 4,
        isCrossfading: false,
        beatCount: 0,
        originalBPM: 180,
        adjustedBPM: 180,
        speedChangeLabel: "+0.0%",
        rightsStatus: "Generated in app",
        updatedAt: Date()
    )

    var dictionary: [String: Any] {
        [
            "targetCadence": targetCadence,
            "isPlaying": isPlaying,
            "playbackStatus": playbackStatus,
            "syncStatus": syncStatus,
            "currentTrack": currentTrack,
            "nextTrack": nextTrack,
            "transitionStatus": transitionStatus,
            "beatsRemaining": beatsRemaining,
            "isCrossfading": isCrossfading,
            "beatCount": beatCount,
            "originalBPM": originalBPM,
            "adjustedBPM": adjustedBPM,
            "speedChangeLabel": speedChangeLabel,
            "rightsStatus": rightsStatus,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
    }

    init(
        targetCadence: Int,
        isPlaying: Bool,
        playbackStatus: String,
        syncStatus: String,
        currentTrack: String,
        nextTrack: String,
        transitionStatus: String,
        beatsRemaining: Int,
        isCrossfading: Bool,
        beatCount: Int,
        originalBPM: Int,
        adjustedBPM: Int,
        speedChangeLabel: String,
        rightsStatus: String,
        updatedAt: Date
    ) {
        self.targetCadence = targetCadence
        self.isPlaying = isPlaying
        self.playbackStatus = playbackStatus
        self.syncStatus = syncStatus
        self.currentTrack = currentTrack
        self.nextTrack = nextTrack
        self.transitionStatus = transitionStatus
        self.beatsRemaining = beatsRemaining
        self.isCrossfading = isCrossfading
        self.beatCount = beatCount
        self.originalBPM = originalBPM
        self.adjustedBPM = adjustedBPM
        self.speedChangeLabel = speedChangeLabel
        self.rightsStatus = rightsStatus
        self.updatedAt = updatedAt
    }

    init?(dictionary: [String: Any]) {
        guard
            let targetCadence = dictionary["targetCadence"] as? Int,
            let isPlaying = dictionary["isPlaying"] as? Bool,
            let playbackStatus = dictionary["playbackStatus"] as? String,
            let syncStatus = dictionary["syncStatus"] as? String,
            let currentTrack = dictionary["currentTrack"] as? String,
            let nextTrack = dictionary["nextTrack"] as? String,
            let transitionStatus = dictionary["transitionStatus"] as? String,
            let beatsRemaining = dictionary["beatsRemaining"] as? Int,
            let isCrossfading = dictionary["isCrossfading"] as? Bool,
            let beatCount = dictionary["beatCount"] as? Int,
            let originalBPM = dictionary["originalBPM"] as? Int,
            let adjustedBPM = dictionary["adjustedBPM"] as? Int,
            let speedChangeLabel = dictionary["speedChangeLabel"] as? String,
            let rightsStatus = dictionary["rightsStatus"] as? String,
            let updatedAtInterval = dictionary["updatedAt"] as? TimeInterval
        else {
            return nil
        }

        self.init(
            targetCadence: targetCadence,
            isPlaying: isPlaying,
            playbackStatus: playbackStatus,
            syncStatus: syncStatus,
            currentTrack: currentTrack,
            nextTrack: nextTrack,
            transitionStatus: transitionStatus,
            beatsRemaining: beatsRemaining,
            isCrossfading: isCrossfading,
            beatCount: beatCount,
            originalBPM: originalBPM,
            adjustedBPM: adjustedBPM,
            speedChangeLabel: speedChangeLabel,
            rightsStatus: rightsStatus,
            updatedAt: Date(timeIntervalSince1970: updatedAtInterval)
        )
    }
}

enum WatchControlAction: String, Sendable {
    case playPause
    case start
    case stop
    case cadenceDelta
}

struct WatchControlMessage: Hashable, Sendable {
    let action: WatchControlAction
    let cadenceDelta: Int

    var dictionary: [String: Any] {
        [
            "kind": "control",
            "action": action.rawValue,
            "cadenceDelta": cadenceDelta
        ]
    }

    static func playPause() -> WatchControlMessage {
        WatchControlMessage(action: .playPause, cadenceDelta: 0)
    }

    static func start() -> WatchControlMessage {
        WatchControlMessage(action: .start, cadenceDelta: 0)
    }

    static func stop() -> WatchControlMessage {
        WatchControlMessage(action: .stop, cadenceDelta: 0)
    }

    static func cadenceDelta(_ value: Int) -> WatchControlMessage {
        WatchControlMessage(action: .cadenceDelta, cadenceDelta: value)
    }

    init?(dictionary: [String: Any]) {
        guard
            let kind = dictionary["kind"] as? String,
            kind == "control",
            let actionValue = dictionary["action"] as? String,
            let action = WatchControlAction(rawValue: actionValue)
        else {
            return nil
        }

        self.action = action
        self.cadenceDelta = dictionary["cadenceDelta"] as? Int ?? 0
    }

    private init(action: WatchControlAction, cadenceDelta: Int) {
        self.action = action
        self.cadenceDelta = cadenceDelta
    }
}
