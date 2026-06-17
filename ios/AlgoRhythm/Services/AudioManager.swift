import AVFoundation

/// Plays the rapid-fire "tick" cue. The click is synthesized at runtime rather
/// than shipped as an audio file, so there's no binary asset to maintain. The
/// session mixes with other audio so it never interrupts the user's music.
final class AudioManager {
    static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var tickBuffer: AVAudioPCMBuffer?
    private var enabled = false

    private init() {}

    /// Spins up the audio graph. Safe to call more than once; only the first
    /// call does work. Kept lazy so we don't touch audio until rapid-fire mode
    /// is actually used.
    func start() {
        guard !enabled else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        guard let format else { return }

        tickBuffer = Self.makeClick(format: format)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            player.play()
            enabled = true
        } catch {
            enabled = false
        }
    }

    func tick() {
        guard enabled, let tickBuffer else { return }
        player.scheduleBuffer(tickBuffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    func stop() {
        guard enabled else { return }
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        enabled = false
    }

    // A tiny exponentially-decaying sine burst reads as a crisp mechanical click.
    private static func makeClick(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let durationSeconds = 0.03
        let frames = AVAudioFrameCount(sampleRate * durationSeconds)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }
        buffer.frameLength = frames

        let frequency = 1_800.0
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let decay = exp(-t * 90.0)
            channel[i] = Float(sin(2.0 * .pi * frequency * t) * decay * 0.5)
        }
        return buffer
    }
}
