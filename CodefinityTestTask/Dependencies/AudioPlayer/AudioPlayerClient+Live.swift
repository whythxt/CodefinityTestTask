import AVFoundation
import Dependencies
import Foundation

actor AudioPlayerActor {
    private var player: AVPlayer?
    private var currentItem: AVPlayerItem?
    private var duration: TimeInterval = 0
    private var currentRate: Float = 1.0
    private var timeObserverToken: Any?

    private var progressContinuations: [UUID: AsyncStream<(TimeInterval, TimeInterval)>.Continuation] = [:]
    private var finishContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    private var finishObserverTask: Task<Void, Never>?

    init() {
        configureAudioSession()
    }

    private nonisolated func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session config failed: \(error)")
        }
    }

    func load(_ url: URL) async throws -> TimeInterval {
        teardownObservers()
        player?.pause()

        let asset = AVURLAsset(url: url)
        let cmDuration = try await asset.load(.duration)
        duration = cmDuration.seconds

        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.automaticallyWaitsToMinimizeStalling = true

        player = newPlayer
        currentItem = item

        installPeriodicObserver(on: newPlayer)
        installFinishObserver(for: item)

        return duration
    }

    func play() {
        guard let player else { return }
        player.playImmediately(atRate: currentRate)
    }

    func pause() {
        player?.pause()
    }

    func seek(to time: TimeInterval) async {
        let clamped = max(0, min(time, duration))

        await player?.seek(
            to: CMTime(seconds: clamped, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    func setRate(_ rate: Double) {
        currentRate = Float(rate)

        if let player, player.timeControlStatus == .playing {
            player.rate = currentRate
        }
    }

    // MARK: Streams

    func makeProgressStream() -> AsyncStream<(TimeInterval, TimeInterval)> {
        let id = UUID()

        return AsyncStream { continuation in
            Task { self.registerProgress(id: id, continuation: continuation) }
            continuation.onTermination = { _ in
                Task { await self.unregisterProgress(id: id) }
            }
        }
    }

    func makeFinishStream() -> AsyncStream<Void> {
        let id = UUID()

        return AsyncStream { continuation in
            Task { self.registerFinish(id: id, continuation: continuation) }
            continuation.onTermination = { _ in
                Task { await self.unregisterFinish(id: id) }
            }
        }
    }

    private func registerProgress(id: UUID, continuation: AsyncStream<(TimeInterval, TimeInterval)>.Continuation) {
        progressContinuations[id] = continuation
    }

    private func unregisterProgress(id: UUID) {
        progressContinuations[id] = nil
    }

    private func registerFinish(id: UUID, continuation: AsyncStream<Void>.Continuation) {
        finishContinuations[id] = continuation
    }

    private func unregisterFinish(id: UUID) {
        finishContinuations[id] = nil
    }

    // MARK: Observers

    private func installPeriodicObserver(on player: AVPlayer) {
        let interval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: 600)

        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else { return }

            let current = time.seconds
            guard !current.isNaN else { return }

            Task { await self.broadcastProgress(current: current) }
        }
    }

    private func installFinishObserver(for item: AVPlayerItem) {
        finishObserverTask?.cancel()

        finishObserverTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: AVPlayerItem.didPlayToEndTimeNotification,
                object: item
            ) {
                await self?.broadcastFinish()
            }
        }
    }

    private func broadcastProgress(current: TimeInterval) {
        let total = duration
        guard total > 0 else { return }

        for continuation in progressContinuations.values {
            continuation.yield((current, total))
        }
    }

    private func broadcastFinish() {
        for continuation in finishContinuations.values {
            continuation.yield(())
        }
    }

    private func teardownObservers() {
        if let token = timeObserverToken, let player {
            player.removeTimeObserver(token)
        }

        timeObserverToken = nil
        finishObserverTask?.cancel()
        finishObserverTask = nil
    }
}

// MARK: - DependencyKey

extension AudioPlayerClient: DependencyKey {
    static var liveValue: AudioPlayerClient {
        let actor = AudioPlayerActor()
        return AudioPlayerClient(
            load: { try await actor.load($0) },
            play: { await actor.play() },
            pause: { await actor.pause() },
            seek: { await actor.seek(to: $0) },
            setRate: { await actor.setRate($0) },
            observeProgress: {
                AsyncStream { continuation in
                    let task = Task {
                        for await tick in await actor.makeProgressStream() {
                            continuation.yield(tick)
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            },
            observeFinish: {
                AsyncStream { continuation in
                    let task = Task {
                        for await _ in await actor.makeFinishStream() {
                            continuation.yield(())
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            }
        )
    }

    static let testValue = AudioPlayerClient(
        load: { _ in 0 },
        play: {},
        pause: {},
        seek: { _ in },
        setRate: { _ in },
        observeProgress: { AsyncStream { $0.finish() } },
        observeFinish: { AsyncStream { $0.finish() } }
    )
}
