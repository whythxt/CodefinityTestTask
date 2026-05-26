import ComposableArchitecture
import Foundation
import Testing

@testable import CodefinityTestTask

@Suite("SummaryFeature")
@MainActor
struct SummaryFeatureTests {
    let chapters: [Chapter] = .stubs

    private func makeStore(
        initialState: SummaryFeature.State? = nil,
        fetchBook: @Sendable @escaping () async throws -> (Book, [Chapter]) = { (.stub, .stubs) }
    ) -> TestStore<SummaryFeature.State, SummaryFeature.Action> {
        TestStore(initialState: initialState ?? SummaryFeature.State()) {
            SummaryFeature()
        } withDependencies: {
            $0.bookClient = BookClient(fetchBook: fetchBook)
            $0.audioPlayer = .mock()
        }
    }

    @Test func onAppear_fetchesBookWhenNoneLoaded() async throws {
        let store = makeStore()

        await store.send(.onAppear)
        await store.receive(\.bookFetched) {
            $0.book = .stub
            $0.chapters = .stubs
            $0.isLoading = false
        }

        await store.receive(\.audio.load)
        await store.receive(\.audio.loaded) {
            $0.audio.duration = 60
            $0.audio.isLoaded = true
        }
    }

    @Test func onAppear_skipsWhenBookAlreadyLoaded() async throws {
        var state = SummaryFeature.State()
        state.book = .stub

        let store = makeStore(initialState: state)
        await store.send(.onAppear)
    }

    @Test func fetchFailed_setsErrorAndStopsLoading() async throws {
        let store = makeStore(fetchBook: { throw BookError.missingChapters(["chapterOne"]) })

        await store.send(.onAppear)
        await store.receive(\.fetchFailed) {
            $0.isLoading = false
            $0.errorMessage = BookError.missingChapters(["chapterOne"]).localizedDescription
        }
    }

    @Test func bookFetched_withEmptyChapters_doesNotLoadAudio() async throws {
        let store = makeStore(fetchBook: { (.stub, []) })

        await store.send(.onAppear)
        await store.receive(\.bookFetched) {
            $0.book = .stub
            $0.chapters = []
            $0.isLoading = false
        }
    }

    @Test func nextChapterTapped_advancesIndex() async throws {
        var state = SummaryFeature.State()
        state.chapters = chapters
        state.currentChapterIndex = 0

        let store = makeStore(initialState: state)

        await store.send(.nextChapterTapped) {
            $0.currentChapterIndex = 1
        }
        await store.receive(\.audio.load)
        await store.receive(\.audio.loaded) {
            $0.audio.duration = 60
            $0.audio.isLoaded = true
        }
    }

    @Test func nextChapterTapped_atLastChapter_seeksToEnd() async throws {
        var state = SummaryFeature.State()
        state.chapters = chapters
        state.currentChapterIndex = 2
        state.audio.isLoaded = true
        state.audio.duration = 60

        let store = makeStore(initialState: state)

        await store.send(.nextChapterTapped)
        await store.receive(\.audio.seek) {
            $0.audio.currentTime = 60
            $0.audio.isSeeking = true
        }
        await store.receive(\.audio.seekCompleted) {
            $0.audio.isSeeking = false
        }
    }

    @Test func previousChapterTapped_decrementsIndex() async throws {
        var state = SummaryFeature.State()
        state.chapters = chapters
        state.currentChapterIndex = 1

        let store = makeStore(initialState: state)

        await store.send(.previousChapterTapped) {
            $0.currentChapterIndex = 0
        }
        await store.receive(\.audio.load)
        await store.receive(\.audio.loaded) {
            $0.audio.duration = 60
            $0.audio.isLoaded = true
        }
    }

    @Test func previousChapterTapped_atFirstChapter_seeksToStart() async throws {
        var state = SummaryFeature.State()
        state.chapters = chapters
        state.currentChapterIndex = 0
        state.audio.isLoaded = true
        state.audio.duration = 60
        state.audio.currentTime = 30

        let store = makeStore(initialState: state)

        await store.send(.previousChapterTapped)
        await store.receive(\.audio.seek) {
            $0.audio.currentTime = 0
            $0.audio.isSeeking = true
        }
        await store.receive(\.audio.seekCompleted) {
            $0.audio.isSeeking = false
        }
    }

    @Test func seekForwardTapped_addsTime() async throws {
        var state = SummaryFeature.State()
        state.audio.currentTime = 20
        state.audio.duration = 60
        state.audio.isLoaded = true

        let store = makeStore(initialState: state)

        await store.send(.seekForwardTapped)
        await store.receive(\.audio.seek) {
            $0.audio.currentTime = 30
            $0.audio.isSeeking = true
        }
        await store.receive(\.audio.seekCompleted) {
            $0.audio.isSeeking = false
        }
    }

    @Test func seekBackwardTapped_subtractsTime() async throws {
        var state = SummaryFeature.State()
        state.audio.currentTime = 20
        state.audio.duration = 60
        state.audio.isLoaded = true

        let store = makeStore(initialState: state)

        await store.send(.seekBackwardTapped)
        await store.receive(\.audio.seek) {
            $0.audio.currentTime = 15
            $0.audio.isSeeking = true
        }
        await store.receive(\.audio.seekCompleted) {
            $0.audio.isSeeking = false
        }
    }

    @Test func seekBackwardTapped_clampsToZero() async throws {
        var state = SummaryFeature.State()
        state.audio.currentTime = 3
        state.audio.duration = 60
        state.audio.isLoaded = true

        let store = makeStore(initialState: state)

        await store.send(.seekBackwardTapped)
        await store.receive(\.audio.seek) {
            $0.audio.currentTime = 0
            $0.audio.isSeeking = true
        }
        await store.receive(\.audio.seekCompleted) {
            $0.audio.isSeeking = false
        }
    }

    @Test func playPauseTapped_doesNothingWhenNotLoaded() async throws {
        let store = makeStore()
        await store.send(.playPauseTapped)
    }

    @Test func playPauseTapped_sendsPlayWhenPaused() async throws {
        var state = SummaryFeature.State()
        state.audio.isLoaded = true

        let store = makeStore(initialState: state)

        await store.send(.playPauseTapped)
        await store.receive(\.audio.play) {
            $0.audio.isPlaying = true
        }
    }

    @Test func playPauseTapped_sendsPauseWhenPlaying() async throws {
        var state = SummaryFeature.State()
        state.audio.isLoaded = true
        state.audio.isPlaying = true

        let store = makeStore(initialState: state)

        await store.send(.playPauseTapped)
        await store.receive(\.audio.pause) {
            $0.audio.isPlaying = false
        }
    }

    @Test func speedTapped_advancesToNextStep() async throws {
        let store = makeStore()
        await store.send(.speedTapped)
        await store.receive(\.audio.setRate) {
            $0.audio.playbackRate = 1.25
        }
    }

    @Test func speedTapped_wrapsFromLastStepToFirst() async throws {
        var state = SummaryFeature.State()
        state.audio.playbackRate = 0.75

        let store = makeStore(initialState: state)

        await store.send(.speedTapped)
        await store.receive(\.audio.setRate) {
            $0.audio.playbackRate = 1.0
        }
    }

    @Test func sliderProgressChanged_setsDragProgress() async throws {
        let store = makeStore()
        await store.send(.sliderProgressChanged(0.4)) {
            $0.dragProgress = 0.4
        }
    }

    @Test func sliderDragEnded_doesNothingWithoutDrag() async throws {
        let store = makeStore()
        await store.send(.sliderDragEnded)
    }

    @Test func sliderDragEnded_seeksToProgress() async throws {
        var state = SummaryFeature.State()
        state.dragProgress = 0.5
        state.audio.duration = 100
        state.audio.isLoaded = true

        let store = makeStore(initialState: state)

        await store.send(.sliderDragEnded) {
            $0.dragProgress = nil
        }
        await store.receive(\.audio.seek) {
            $0.audio.currentTime = 50
            $0.audio.isSeeking = true
        }
        await store.receive(\.audio.seekCompleted) {
            $0.audio.isSeeking = false
        }
    }

    @Test func audioFinished_doesNothingAtLastChapter() async throws {
        var state = SummaryFeature.State()
        state.chapters = chapters
        state.currentChapterIndex = 2
        state.audio.isPlaying = true

        let store = makeStore(initialState: state)

        await store.send(.audio(.finished)) {
            $0.audio.isPlaying = false
        }
    }

    @Test func audioFinished_advancesAndAutoPlaysNextChapter() async throws {
        var state = SummaryFeature.State()
        state.chapters = chapters
        state.currentChapterIndex = 0
        state.audio.isPlaying = true

        let store = makeStore(initialState: state)

        await store.send(.audio(.finished)) {
            $0.audio.isPlaying = false
            $0.currentChapterIndex = 1
            $0.autoPlayOnLoad = true
        }
        await store.receive(\.audio.load)
        await store.receive(\.audio.loaded) {
            $0.audio.duration = 60
            $0.audio.isLoaded = true
            $0.autoPlayOnLoad = false
        }
        await store.receive(\.audio.play) {
            $0.audio.isPlaying = true
        }
    }

    @Test func audioLoaded_withAutoPlayFlag_sendsPlay() async throws {
        var state = SummaryFeature.State()
        state.autoPlayOnLoad = true

        let store = makeStore(initialState: state)

        await store.send(.audio(.loaded(60))) {
            $0.audio.duration = 60
            $0.audio.isLoaded = true
            $0.autoPlayOnLoad = false
        }
        await store.receive(\.audio.play) {
            $0.audio.isPlaying = true
        }
    }

    @Test func audioLoaded_withoutAutoPlayFlag_doesNotPlay() async throws {
        let store = makeStore()
        await store.send(.audio(.loaded(60))) {
            $0.audio.duration = 60
            $0.audio.isLoaded = true
        }
    }

    @Test func audioFailed_propagatesErrorToParentState() async throws {
        var state = SummaryFeature.State()
        state.audio.isLoaded = true
        state.audio.isPlaying = true
        
        let store = makeStore(initialState: state)

        await store.send(.audio(.failed("Network error"))) {
            $0.audio.isLoaded = false
            $0.audio.isPlaying = false
            $0.audio.errorMessage = "Network error"
            $0.errorMessage = "Network error"
        }
    }
}
