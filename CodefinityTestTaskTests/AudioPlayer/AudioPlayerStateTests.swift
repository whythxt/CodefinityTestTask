import Testing

@testable import CodefinityTestTask

@Suite("AudioPlayerFeature.State")
struct AudioPlayerStateTests {
    @Test func progress_isZeroWhenDurationIsZero() {
        #expect(AudioPlayerFeature.State().progress == 0)
    }

    @Test func progress_returnsCorrectFraction() {
        var state = AudioPlayerFeature.State()
        state.currentTime = 30
        state.duration = 60

        #expect(state.progress == 0.5)
    }

    @Test func progress_clampsToOne() {
        var state = AudioPlayerFeature.State()
        state.currentTime = 90
        state.duration = 60
        
        #expect(state.progress == 1.0)
    }
}
