import Foundation

enum DisplayMode: String, CaseIterable, Identifiable {
    case audio
    case text

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .audio: "headphones"
        case .text: "text.alignleft"
        }
    }
}
