import Dependencies
import Foundation

struct BookClient: Sendable {
    var fetchBook: @Sendable () async throws -> (Book, [Chapter])
}

enum BookError: Error, LocalizedError {
    case missingChapters([String])

    var errorDescription: String? {
        switch self {
        case .missingChapters(let names):
            return "Missing audio chapters: \(names.joined(separator: ", "))"
        }
    }
}

extension DependencyValues {
    var bookClient: BookClient {
        get { self[BookClient.self] }
        set { self[BookClient.self] = newValue }
    }
}
