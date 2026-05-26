import ComposableArchitecture
import Foundation

@testable import CodefinityTestTask

extension AudioPlayerClient {
    static func mock(
        load: @Sendable @escaping (URL) async throws -> TimeInterval = { _ in 60 },
        play: @Sendable @escaping () async -> Void = {},
        pause: @Sendable @escaping () async -> Void = {},
        seek: @Sendable @escaping (TimeInterval) async -> Void = { _ in },
        setRate: @Sendable @escaping (Double) async -> Void = { _ in }
    ) -> Self {
        Self(
            load: load,
            play: play,
            pause: pause,
            seek: seek,
            setRate: setRate,
            observeProgress: { AsyncStream { $0.finish() } },
            observeFinish: { AsyncStream { $0.finish() } }
        )
    }
}

extension Book {
    static let stub = Book(id: "local", title: "The Eskimo Twins", author: "Lucy Fitch Perkins", description: "")
}

extension Chapter {
    static func make(_ n: Int) -> Chapter {
        Chapter(id: "\(n)", number: n, audioURL: URL(string: "file://ch\(n).mp3")!)
    }
}

extension Array where Element == Chapter {
    static var stubs: [Chapter] { (1...3).map { .make($0) } }
}
