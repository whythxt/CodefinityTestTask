import Dependencies
import Foundation

struct AudioPlayerClient: Sendable {
    var load: @Sendable (URL) async throws -> TimeInterval
    var play: @Sendable () async -> Void
    var pause: @Sendable () async -> Void
    var seek: @Sendable (TimeInterval) async -> Void
    var setRate: @Sendable (Double) async -> Void
    var observeProgress: @Sendable () -> AsyncStream<(current: TimeInterval, total: TimeInterval)>
    var observeFinish: @Sendable () -> AsyncStream<Void>
}

extension DependencyValues {
    var audioPlayer: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
