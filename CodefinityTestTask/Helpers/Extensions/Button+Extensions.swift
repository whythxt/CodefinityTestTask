import SwiftUI

struct TapScaleButtonStyle: ButtonStyle {
    private let pressedScale: CGFloat = 0.95
    private let animation: Animation = .easeInOut(duration: 0.3)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TapScaleButtonStyle {
    static var tapScale: TapScaleButtonStyle {
        TapScaleButtonStyle()
    }
}
