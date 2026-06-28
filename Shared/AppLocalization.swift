import Foundation

enum AppLanguage: String, CaseIterable, Hashable, Identifiable {
    case followSystem
    case english
    case chinese

    var id: String { rawValue }

    var title: String {
        switch self {
        case .followSystem:
            "Follow System"
        case .english:
            "English"
        case .chinese:
            "中文"
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .followSystem:
            nil
        case .english:
            "en"
        case .chinese:
            "zh-Hans"
        }
    }

    var effectiveUsesChinese: Bool {
        switch self {
        case .chinese:
            true
        case .english:
            false
        case .followSystem:
            Locale.preferredLanguages.first?.hasPrefix("zh") == true
        }
    }

    static func preferred(from rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .followSystem
    }

    static func debugOverride(from arguments: [String] = CommandLine.arguments) -> AppLanguage? {
        guard let flagIndex = arguments.firstIndex(of: "-BeatrunLanguage") else { return nil }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else { return nil }

        switch arguments[valueIndex].lowercased() {
        case "zh", "zh-hans", "chinese":
            return .chinese
        case "en", "english":
            return .english
        case "system", "follow":
            return .followSystem
        default:
            return nil
        }
    }
}

struct AppCopy {
    let language: AppLanguage

    func callAsFunction(_ key: String) -> String {
        guard let entry = Self.table[key] else { return key }
        return language.effectiveUsesChinese ? entry.zh : entry.en
    }

    private static let table: [String: (en: String, zh: String)] = [
        "about": ("About", "关于"),
        "adjust.cadence": ("Adjust cadence", "调整步频"),
        "app.language": ("App Language", "应用语言"),
        "authorized.tracks": ("Authorized Tracks", "授权曲库"),
        "backing.volume": ("Backing music volume", "伴奏音量"),
        "beat.rules": ("1:1 BPM only, +/-10% retime, no double-time or half-time matching.", "仅 1:1 BPM，变速限制 +/-10%，不使用双倍速或半速匹配。"),
        "cadence": ("Cadence", "步频"),
        "cadence.default": ("Default Cadence", "默认步频"),
        "cadence.range": ("Target cadence stays between 140 and 200 SPM.", "目标步频限制在 140 到 200 SPM。"),
        "cadence.target": ("Target Cadence", "目标步频"),
        "click.volume": ("Metronome click volume", "节拍器音量"),
        "competition.mvp": ("Competition MVP", "比赛 MVP"),
        "core.controls": ("Core Controls", "核心控制"),
        "details": ("Details", "详情"),
        "done": ("Done", "完成"),
        "haptics": ("Haptics", "触感"),
        "haptics.note": ("Play a light click haptic for local Watch controls.", "本地手表控制时播放轻微点击触感。"),
        "health.watch": ("HealthKit workout permissions are requested on Apple Watch when a workout starts.", "HealthKit 训练权限会在 Apple Watch 开始训练时请求。"),
        "imported.cc": ("Imported MP3 files and bundled CC0 tracks stay available when the system music library is empty or unavailable.", "系统曲库为空或不可用时，已导入 MP3 与内置 CC0 音乐仍可使用。"),
        "language.note": ("Language changes apply immediately to app UI labels. Dynamic track metadata keeps the source language.", "语言切换会立即应用到应用界面文案。动态歌曲元数据保留来源语言。"),
        "legal.note": ("DRM or cloud-only Apple Music tracks are metadata-only. Tempo-adjusted playback is limited to legal local, imported, or bundled CC0 files.", "DRM 或仅云端 Apple Music 曲目只作为元数据使用。变速播放仅用于合法本地、导入或内置 CC0 文件。"),
        "library": ("Music Library", "音乐库"),
        "library.open.settings": ("Open app settings", "打开应用设置"),
        "library.rescan": ("Rescan Library", "重新扫描曲库"),
        "library.scan": ("Authorize or rescan music library", "授权或重新扫描音乐库"),
        "library.summary": ("Library Summary", "曲库摘要"),
        "match.details": ("Tempo Details", "节奏详情"),
        "matches": ("Matches", "匹配"),
        "metronome.ready": ("Metronome ready", "节拍器就绪"),
        "music.matching": ("Music matching", "音乐匹配"),
        "music.type": ("Music Type", "音乐类型"),
        "needs.bpm": ("Needs BPM", "需要 BPM"),
        "next.track": ("Next track", "下一首"),
        "no.legal.match": ("No legal match", "暂无合法匹配"),
        "now.playing": ("Now Playing", "正在播放"),
        "open.details": ("Open Details", "打开详情"),
        "open.recommendations": ("Open Recommendations", "打开推荐"),
        "open.settings": ("Open Settings", "打开设置"),
        "playback": ("Playback", "播放"),
        "playback.details": ("Playback Details", "播放详情"),
        "recommendations": ("Recommendations", "推荐"),
        "reset.preferences": ("Reset Local Preferences", "重置本地偏好"),
        "reset.preferences.note": ("Restores language, default cadence, music type, and current cadence without deleting imported audio.", "恢复语言、默认步频、音乐类型和当前步频，不会删除已导入音频。"),
        "retiming": ("Retiming", "可变速"),
        "rights": ("Rights", "版权"),
        "run.mix": ("Run mix", "跑步混音"),
        "run.subtitle": ("Library-matched run audio", "按曲库匹配跑步音频"),
        "scan.again": ("Search again", "重新搜索"),
        "scanned": ("Scanned", "已扫描"),
        "settings": ("Settings", "设置"),
        "settings.title": ("Beatrun Settings", "Beatrun 设置"),
        "source": ("Source", "来源"),
        "spm": ("SPM", "SPM"),
        "state": ("State", "状态"),
        "sync": ("Sync", "同步"),
        "tempo.fit": ("Tempo Fit", "节奏匹配"),
        "watch.settings": ("Watch Settings", "手表设置"),
        "watch.sync": ("Watch Sync", "手表同步"),
        "watch.sync.note": ("Apple Watch receives cadence, playback, and queue state through WatchConnectivity.", "Apple Watch 通过 WatchConnectivity 接收步频、播放和队列状态。"),
        "workout": ("Workout", "训练")
    ]
}
