import Foundation
import Testing

@testable import CodefinityTestTask

@Suite("SummaryFeature.State")
struct SummaryStateTests {
    @Test func chapterLabel_emptyWithNoChapters() {
        #expect(SummaryFeature.State().chapterLabel == "")
    }

    @Test func chapterLabel_formatsIndexAndCount() {
        var state = SummaryFeature.State()
        state.book = .stub
        state.currentChapterIndex = 1

        #expect(state.chapterLabel == "Key point 2 of 3")
    }

    @Test func sliderProgress_usesAudioProgress() {
        var state = SummaryFeature.State()
        state.audio.currentTime = 30
        state.audio.duration = 60

        #expect(state.sliderProgress == 0.5)
    }

    @Test func sliderProgress_prefersDragProgressOverAudio() {
        var state = SummaryFeature.State()
        state.audio.currentTime = 30
        state.audio.duration = 60
        state.dragProgress = 0.8

        #expect(state.sliderProgress == 0.8)
    }

    @Test func displayedCurrentTime_usesDragProgressWhileDragging() {
        var state = SummaryFeature.State()
        state.audio.currentTime = 10
        state.audio.duration = 100
        state.dragProgress = 0.5

        #expect(state.displayedCurrentTime == 50)
    }

    @Test func formattedCurrentTime_zeroPadsMinutes() {
        var state = SummaryFeature.State()
        state.audio.currentTime = 360

        #expect(state.formattedCurrentTime == "06:00")
    }

    @Test func canGoNext_trueWhenNotAtLastChapter() {
        var state = SummaryFeature.State()
        state.book = .stub
        state.currentChapterIndex = 1

        #expect(state.canGoNext)
    }

    @Test func canGoNext_falseAtLastChapter() {
        var state = SummaryFeature.State()
        state.book = .stub
        state.currentChapterIndex = 2

        #expect(!state.canGoNext)
    }

    @Test func isBookFinished_trueAtLastChapterEnd() {
        var state = SummaryFeature.State()
        state.book = .stub
        state.currentChapterIndex = 2
        state.audio.currentTime = 60
        state.audio.duration = 60

        #expect(state.isBookFinished)
    }

    @Test func isBookFinished_falseWhenTimeHasNotReachedEnd() {
        var state = SummaryFeature.State()
        state.book = .stub
        state.currentChapterIndex = 2
        state.audio.currentTime = 30
        state.audio.duration = 60

        #expect(!state.isBookFinished)
    }

    @Test func speedLabel_formatsRate() {
        var state = SummaryFeature.State()
        state.audio.playbackRate = 1.5
        let expected = "Speed x\(1.5.formatted(.number.precision(.fractionLength(0...2))))"

        #expect(state.speedLabel == expected)
    }
}
