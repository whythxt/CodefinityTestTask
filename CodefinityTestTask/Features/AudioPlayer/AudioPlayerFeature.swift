import ComposableArchitecture
import Foundation

@Reducer
struct AudioPlayerFeature {
    @ObservableState
    struct State: Equatable {
        var isPlaying = false
        var currentTime: TimeInterval = 0
        var duration: TimeInterval = 0
        var playbackRate: Double = 1.0
        var isLoaded = false
        var isSeeking = false
        var errorMessage: String?

        var progress: Double {
            guard duration > 0 else { return 0 }
            return min(currentTime / duration, 1.0)
        }
    }

    enum Action {
        case load(URL)
        case play
        case pause
        case seek(TimeInterval)
        case setRate(Double)
        case progressUpdated(TimeInterval)
        case finished
        case loaded(TimeInterval)
        case failed(String)
        case seekCompleted
    }

    @Dependency(\.audioPlayer) var audioPlayer

    nonisolated enum CancelID {
        case load, progress, finish, transport, seek
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case let .load(url):
                state.isLoaded = false
                state.isPlaying = false
                state.currentTime = 0
                state.duration = 0
                state.isSeeking = false
                state.errorMessage = nil

                return .merge(
                    .cancel(id: CancelID.progress),
                    .cancel(id: CancelID.finish),
                    .run { [rate = state.playbackRate] send in
                        do {
                            await audioPlayer.pause()
                            let duration = try await audioPlayer.load(url)
                            await audioPlayer.setRate(rate)
                            await send(.loaded(duration))
                        } catch {
                            await send(.failed(error.localizedDescription))
                        }
                    }
                    .cancellable(id: CancelID.load, cancelInFlight: true)
                )

            case let .loaded(duration):
                state.duration = duration
                state.isLoaded = true
                return .merge(observeProgress(), observeFinish())

            case .play:
                guard state.isLoaded else { return .none }
                state.isPlaying = true
                return .run { _ in await audioPlayer.play() }
                    .cancellable(id: CancelID.transport, cancelInFlight: true)

            case .pause:
                state.isPlaying = false
                return .run { _ in await audioPlayer.pause() }
                    .cancellable(id: CancelID.transport, cancelInFlight: true)

            case let .seek(time):
                let clamped = max(0, min(time, state.duration))
                state.currentTime = clamped
                state.isSeeking = true

                return .run { send in
                    await audioPlayer.seek(clamped)
                    await send(.seekCompleted)
                }
                .cancellable(id: CancelID.seek, cancelInFlight: true)

            case .seekCompleted:
                state.isSeeking = false
                return .none

            case let .setRate(rate):
                state.playbackRate = rate
                return .run { _ in await audioPlayer.setRate(rate) }

            case let .progressUpdated(current):
                guard !state.isSeeking else { return .none }
                state.currentTime = current
                return .none

            case .finished:
                state.isPlaying = false
                return .none

            case let .failed(message):
                state.isLoaded = false
                state.isPlaying = false
                state.errorMessage = message
                return .none
            }
        }
    }

    private func observeProgress() -> Effect<Action> {
        let player = audioPlayer

        return .run { send in
            for await (current, _) in player.observeProgress() {
                await send(.progressUpdated(current))
            }
        }
        .cancellable(id: CancelID.progress, cancelInFlight: true)
    }

    private func observeFinish() -> Effect<Action> {
        let player = audioPlayer

        return .run { send in
            for await _ in player.observeFinish() {
                await send(.finished)
            }
        }
        .cancellable(id: CancelID.finish, cancelInFlight: true)
    }
}
