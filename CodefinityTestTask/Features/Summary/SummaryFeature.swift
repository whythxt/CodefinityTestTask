import ComposableArchitecture
import Foundation

// ❓ Q1 [СПІВБЕСІДА]: Чому обрав TCA, а не MVVM? Назви плюси і МІНУСИ TCA.
@Reducer
struct SummaryFeature {
    @ObservableState
    struct State: Equatable {
        var book: Book?
        var currentChapterIndex = 0
        var isLoading = true
        var errorMessage: String?
        var autoPlayOnLoad = false
        var dragProgress: Double?

        var audio = AudioPlayerFeature.State()

        var chapters: [Chapter] { book?.chapters ?? [] }

        var currentChapter: Chapter? {
            chapters.indices.contains(currentChapterIndex) ? chapters[currentChapterIndex] : nil
        }

        var isDragging: Bool { dragProgress != nil }

        var sliderProgress: Double {
            dragProgress ?? audio.progress
        }

        var chapterLabel: String {
            guard !chapters.isEmpty else { return "" }
            return "Key point \(currentChapterIndex + 1) of \(chapters.count)"
        }

        var displayedCurrentTime: TimeInterval {
            isDragging ? (dragProgress ?? 0) * audio.duration : audio.currentTime
        }

        var formattedCurrentTime: String {
            Duration.seconds(displayedCurrentTime).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
        }

        var formattedDuration: String {
            Duration.seconds(audio.duration).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
        }

        var speedLabel: String {
            "Speed x\(audio.playbackRate.formatted(.number.precision(.fractionLength(0...2))))"
        }

        var playButtonIcon: String {
            audio.isPlaying ? "pause.fill" : "play.fill"
        }

        var canGoNext: Bool { currentChapterIndex < chapters.count - 1 }
        var canGoPrevious: Bool { currentChapterIndex > 0 }

        var isBookFinished: Bool {
            !canGoNext && audio.duration > 0 && audio.currentTime >= audio.duration
        }
    }

    enum Action {
        case onAppear
        case bookFetched(Book)
        case fetchFailed(String)
        case nextChapterTapped
        case previousChapterTapped
        case seekForwardTapped
        case seekBackwardTapped
        case playPauseTapped
        case speedTapped
        case sliderProgressChanged(Double)
        case sliderDragEnded
        case audio(AudioPlayerFeature.Action)
    }

    @Dependency(\.bookClient) var bookClient

    // ❓ Q10 [СПІВБЕСІДА]: Поясни порядок цього масиву і як працює цикл швидкостей
    // (`% count`). Що робить `?? 0` при невідомій швидкості?
    private static let speedSteps: [Double] = [1.0, 1.25, 1.5, 1.75, 2.0, 0.5, 0.75]

    var body: some Reducer<State, Action> {
        // ❓ Q2 [СПІВБЕСІДА]: Поясни розділення parent (Summary) і child (AudioPlayer)
        // через Scope. Де межа відповідальності? Чому AudioPlayer окремо?
        Scope(state: \.audio, action: \.audio) {
            AudioPlayerFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.book == nil else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let book = try await bookClient.fetchBook()
                        await send(.bookFetched(book))
                    } catch {
                        await send(.fetchFailed(error.localizedDescription))
                    }
                }

            case let .bookFetched(book):
                state.book = book
                state.isLoading = false

                guard let first = book.chapters.first else {
                    state.errorMessage = "No chapters found."
                    return .none
                }

                state.autoPlayOnLoad = false
                state.dragProgress = nil
                return .send(.audio(.load(first.audioURL)))

            case let .fetchFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .nextChapterTapped:
                guard state.canGoNext else {
                    return .send(.audio(.seek(state.audio.duration)))
                }

                state.currentChapterIndex += 1
                return loadCurrentChapter(in: &state, autoPlay: state.audio.isPlaying)

            case .previousChapterTapped:
                guard state.canGoPrevious else {
                    return .send(.audio(.seek(0)))
                }

                state.currentChapterIndex -= 1
                return loadCurrentChapter(in: &state, autoPlay: state.audio.isPlaying)

            case .seekForwardTapped:
                let target = min(state.audio.currentTime + 10, state.audio.duration)
                return .send(.audio(.seek(target)))

            case .seekBackwardTapped:
                let target = max(state.audio.currentTime - 5, 0)
                return .send(.audio(.seek(target)))

            case .playPauseTapped:
                guard state.audio.isLoaded else { return .none }
                return .send(.audio(state.audio.isPlaying ? .pause : .play))

            case .speedTapped:
                let steps = Self.speedSteps
                let currentIndex = steps.firstIndex(of: state.audio.playbackRate) ?? 0
                let nextRate = steps[(currentIndex + 1) % steps.count]
                return .send(.audio(.setRate(nextRate)))

            case let .sliderProgressChanged(progress):
                state.dragProgress = progress
                return .none

            case .sliderDragEnded:
                guard let progress = state.dragProgress else { return .none }
                state.dragProgress = nil
                let seekTime = progress * state.audio.duration
                return .send(.audio(.seek(seekTime)))

            case let .audio(audioAction):
                switch audioAction {
                case .finished:
                    guard state.canGoNext else { return .none }
                    state.currentChapterIndex += 1
                    return loadCurrentChapter(in: &state, autoPlay: true)

                case .loaded:
                    if state.autoPlayOnLoad {
                        state.autoPlayOnLoad = false
                        return .send(.audio(.play))
                    }
                    return .none

                case let .failed(message):
                    state.errorMessage = message
                    return .none

                default:
                    return .none
                }
            }
        }
    }

    private func loadCurrentChapter(in state: inout State, autoPlay: Bool) -> Effect<Action> {
        guard let chapter = state.currentChapter else { return .none }
        state.autoPlayOnLoad = autoPlay
        state.dragProgress = nil
        return .send(.audio(.load(chapter.audioURL)))
    }
}
