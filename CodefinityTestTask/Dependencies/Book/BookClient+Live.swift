import Foundation
import Dependencies

extension BookClient: DependencyKey {
    static var liveValue: BookClient {
        BookClient(
            // ❓ Q15 [СПІВБЕСІДА]: fetchBook — `async throws`, хоч це лише читання mp3 з бандла.
            // Навіщо async для синхронної операції? Що змінилося б для реального API?
            fetchBook: {
                let resources = [
                    "chapterOne", "chapterTwo", "chapterThree", "chapterFour", "chapterFive",
                    "chapterSix", "chapterSeven", "chapterEight", "chapterNine", "chapterTen",
                ]

                var chapters: [Chapter] = []
                var missing: [String] = []

                for (index, resource) in resources.enumerated() {
                    if let url = Bundle.main.url(forResource: resource, withExtension: "mp3") {
                        chapters.append(Chapter(id: String(index + 1), number: index + 1, audioURL: url))
                    } else {
                        missing.append(resource)
                    }
                }

                guard missing.isEmpty else { throw BookError.missingChapters(missing) }

                return Book(
                    id: "local",
                    title: "The Eskimo Twins",
                    author: "Lucy Fitch Perkins",
                    chapters: chapters
                )
            }
        )
    }

    static let testValue = BookClient(
        fetchBook: {
            Book(id: "test", title: "Test", author: "Test", chapters: [])
        }
    )
}
