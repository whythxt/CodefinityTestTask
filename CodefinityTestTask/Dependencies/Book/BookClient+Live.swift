import Foundation
import Dependencies

extension BookClient: DependencyKey {
    static var liveValue: BookClient {
        BookClient(
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

                let book = Book(
                    id: "local",
                    title: "The Eskimo Twins",
                    author: "Lucy Fitch Perkins",
                    description: ""
                )

                return (book, chapters)
            }
        )
    }

    static let testValue = BookClient(
        fetchBook: {
            (
                Book(id: "test", title: "Test", author: "Test", description: ""),
                []
            )
        }
    )
}
