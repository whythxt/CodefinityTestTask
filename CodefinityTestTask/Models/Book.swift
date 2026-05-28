import Foundation

struct Book: Equatable {
    let id: String
    let title: String
    let author: String
    let chapters: [Chapter]
}

struct Chapter: Equatable, Identifiable {
    let id: String
    let number: Int
    let audioURL: URL
}
