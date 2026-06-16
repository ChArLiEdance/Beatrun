import AVFoundation
import Foundation

struct AudioBPMAnalysis: Hashable {
    let bpm: Int
    let confidence: Double
    let source: String
}

enum AudioBPMAnalyzerError: LocalizedError {
    case emptyAudio
    case unsupportedPCM
    case tooShort
    case tempoUnavailable

    var errorDescription: String? {
        switch self {
        case .emptyAudio:
            "Audio file is empty."
        case .unsupportedPCM:
            "Audio file could not be decoded into PCM samples."
        case .tooShort:
            "Audio file is too short for BPM analysis."
        case .tempoUnavailable:
            "BPM analysis could not find a stable tempo."
        }
    }
}

enum AudioBPMAnalyzer {
    static func analyze(url: URL) async throws -> AudioBPMAnalysis {
        if let taggedBPM = await readTaggedBPM(url: url) {
            return AudioBPMAnalysis(
                bpm: taggedBPM,
                confidence: 0.92,
                source: "BPM tag"
            )
        }

        let waveformBPM = try estimateWaveformBPM(url: url)
        return AudioBPMAnalysis(
            bpm: waveformBPM.bpm,
            confidence: waveformBPM.confidence,
            source: "Automatic waveform BPM analysis"
        )
    }

    private static func readTaggedBPM(url: URL) async -> Int? {
        let asset = AVURLAsset(url: url)
        let metadata = ((try? await asset.load(.metadata)) ?? [])
            + ((try? await asset.load(.commonMetadata)) ?? [])
        for item in metadata {
            let key = item.commonKey?.rawValue.lowercased()
                ?? item.identifier?.rawValue.lowercased()
                ?? String(describing: item.key).lowercased()
            guard key.contains("bpm") || key.contains("tbpm") else { continue }
            let value = try? await item.load(.value)
            if let number = value as? NSNumber {
                let bpm = number.intValue
                if bpm > 0 { return normalizedRunningBPM(bpm) }
            }
            if let text = value as? String,
               let bpm = Int(text.filter(\.isNumber)),
               bpm > 0 {
                return normalizedRunningBPM(bpm)
            }
        }
        return nil
    }

    private static func estimateWaveformBPM(url: URL) throws -> (bpm: Int, confidence: Double) {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let sampleRate = format.sampleRate
        let channels = Int(format.channelCount)
        let maximumSeconds = 90.0
        let frameCount = AVAudioFrameCount(min(Double(file.length), maximumSeconds * sampleRate))
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioBPMAnalyzerError.emptyAudio
        }

        try file.read(into: buffer, frameCount: frameCount)
        guard let channelData = buffer.floatChannelData else {
            throw AudioBPMAnalyzerError.unsupportedPCM
        }

        let totalFrames = Int(buffer.frameLength)
        let hopSize = max(256, Int(sampleRate / 100.0))
        let windowSize = max(hopSize * 2, 512)
        guard totalFrames > windowSize * 4 else {
            throw AudioBPMAnalyzerError.tooShort
        }

        var energy: [Float] = []
        energy.reserveCapacity(totalFrames / hopSize)
        var frameStart = 0
        while frameStart + windowSize < totalFrames {
            var sum: Float = 0
            for frame in frameStart..<(frameStart + windowSize) {
                var mixedSample: Float = 0
                for channel in 0..<channels {
                    mixedSample += channelData[channel][frame]
                }
                mixedSample /= Float(max(1, channels))
                sum += mixedSample * mixedSample
            }
            energy.append(sqrt(sum / Float(windowSize)))
            frameStart += hopSize
        }

        guard energy.count > 16 else {
            throw AudioBPMAnalyzerError.tooShort
        }

        var onset: [Float] = []
        onset.reserveCapacity(energy.count - 1)
        for index in 1..<energy.count {
            onset.append(max(0, energy[index] - energy[index - 1]))
        }

        let mean = onset.reduce(Float(0), +) / Float(max(1, onset.count))
        let centered = onset.map { max(0, $0 - mean) }
        let envelopeRate = sampleRate / Double(hopSize)
        var rankedScores: [(bpm: Int, score: Double)] = []
        rankedScores.reserveCapacity(141)

        for bpm in 80...220 {
            let lag = Int((60.0 * envelopeRate / Double(bpm)).rounded())
            guard lag > 1, lag < centered.count else { continue }
            var score = 0.0
            for index in lag..<centered.count {
                score += Double(centered[index] * centered[index - lag])
            }
            rankedScores.append((bpm: bpm, score: score))
        }

        guard let best = rankedScores.max(by: { $0.score < $1.score }),
              best.score > 0 else {
            throw AudioBPMAnalyzerError.tempoUnavailable
        }

        let second = rankedScores
            .filter { abs($0.bpm - best.bpm) > 4 }
            .max(by: { $0.score < $1.score })?.score ?? 0
        let confidence = min(0.92, max(0.48, best.score / max(best.score + second, 0.0001)))
        return (normalizedRunningBPM(best.bpm), confidence)
    }

    private static func normalizedRunningBPM(_ bpm: Int) -> Int {
        var normalized = bpm
        while normalized < 140 {
            normalized *= 2
        }
        while normalized > 220 {
            normalized = Int((Double(normalized) / 2.0).rounded())
        }
        return min(max(normalized, 80), 220)
    }
}
