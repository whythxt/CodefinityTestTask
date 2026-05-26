import ComposableArchitecture
import Foundation
import Testing

@testable import CodefinityTestTask

@Suite("AudioPlayerFeature")
@MainActor
struct AudioPlayerFeatureTests {
    let testURL = URL(string: "file://chapter.mp3")!

    private func makeStore(
        initialState: AudioPlayerFeature.State? = nil,
        load: @Sendable @escaping (URL) async throws -> TimeInterval = { _ in 60 }
    ) -> TestStore<AudioPlayerFeature.State, AudioPlayerFeature.Action> {
        TestStore(initialState: initialState ?? AudioPlayerFeature.State()) {
            AudioPlayerFeature()
        } withDependencies: {
            $0.audioPlayer = .mock(load: load)
        }
    }

    @Test func load_successfullySetsStateAndDuration() async throws {
        let store = makeStore()
        await store.send(.load(testURL))
        await store.receive(\.loaded) {
            $0.duration = 60
            $0.isLoaded = true
        }
    }

    @Test func load_sendsFailedOnError() async throws {
        let store = makeStore(load: { _ in throw URLError(.cannotOpenFile) })
        await store.send(.load(testURL))
        await store.receive(\.failed) {
            $0.errorMessage = URLError(.cannotOpenFile).localizedDescription
        }
    }

    @Test func play_setsIsPlayingWhenLoaded() async throws {
        var state = AudioPlayerFeature.State()
        state.isLoaded = true

        let store = makeStore(initialState: state)
        await store.send(.play) {
            $0.isPlaying = true
        }
    }

    @Test func pause_clearsIsPlaying() async throws {
        var state = AudioPlayerFeature.State()
        state.isPlaying = true

        let store = makeStore(initialState: state)
        await store.send(.pause) {
            $0.isPlaying = false
        }
    }

    @Test func seek_updatesTimeAndSetsSeeking() async throws {
        var state = AudioPlayerFeature.State()
        state.duration = 100

        let store = makeStore(initialState: state)
        await store.send(.seek(40)) {
            $0.currentTime = 40
            $0.isSeeking = true
        }
        await store.receive(\.seekCompleted) {
            $0.isSeeking = false
        }
    }

    @Test func seek_clampsToDuration() async throws {
        var state = AudioPlayerFeature.State()
        state.duration = 60

        let store = makeStore(initialState: state)
        await store.send(.seek(120)) {
            $0.currentTime = 60
            $0.isSeeking = true
        }
        await store.receive(\.seekCompleted) {
            $0.isSeeking = false
        }
    }

    @Test func setRate_updatesPlaybackRate() async throws {
        let store = makeStore()
        await store.send(.setRate(1.5)) {
            $0.playbackRate = 1.5
        }
    }

    @Test func progressUpdated_updatesCurrentTime() async throws {
        let store = makeStore()
        await store.send(.progressUpdated(25)) {
            $0.currentTime = 25
        }
    }

    @Test func progressUpdated_ignoredWhileSeeking() async throws {
        var state = AudioPlayerFeature.State()
        state.isSeeking = true

        let store = makeStore(initialState: state)
        await store.send(.progressUpdated(25))
    }

    @Test func finished_clearsIsPlaying() async throws {
        var state = AudioPlayerFeature.State()
        state.isPlaying = true

        let store = makeStore(initialState: state)
        await store.send(.finished) {
            $0.isPlaying = false
        }
    }

    @Test func failed_setsErrorAndClearsLoadedState() async throws {
        var state = AudioPlayerFeature.State()
        state.isLoaded = true
        state.isPlaying = true

        let store = makeStore(initialState: state)
        await store.send(.failed("Something went wrong")) {
            $0.isLoaded = false
            $0.isPlaying = false
            $0.errorMessage = "Something went wrong"
        }
    }
}
