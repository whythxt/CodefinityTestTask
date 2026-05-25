import SwiftUI

struct PlayerControls: View {
    let playButtonIcon: String
    let onPrevious: () -> Void
    let onBackward: () -> Void
    let onPlayPause: () -> Void
    let onForward: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 30) {
            controlButton(icon: "backward.end.fill", action: onPrevious)
            controlButton(icon: "gobackward.5", action: onBackward)
            controlButton(icon: playButtonIcon, action: onPlayPause)
            controlButton(icon: "goforward.10", action: onForward)
            controlButton(icon: "forward.end.fill", action: onNext)
        }
        .padding(.top, 20)
    }

    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.appBlack)
        }
        .buttonStyle(.tapScale)
    }
}

#Preview {
    PlayerControls(
        playButtonIcon: "play.fill",
        onPrevious: {},
        onBackward: {},
        onPlayPause: {},
        onForward: {},
        onNext: {}
    )
    .padding()
}
