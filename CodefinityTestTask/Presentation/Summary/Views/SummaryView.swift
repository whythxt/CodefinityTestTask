import SwiftUI

struct SummaryView: View {
    @State private var selectedDisplay: DisplayMode = .audio

    @Namespace private var toggleAnimation

    var body: some View {
        VStack(spacing: 20) {
            coverImage

            summaryTitle

            progressBar

            speedButton

            playerControls

            modeToggle
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.appBackground)
    }
}

// MARK: - UI Components

private extension SummaryView {
    private var coverImage: some View {
        Rectangle()
            .fill(.secondary)
            .frame(width: 210, height: 350)
    }

    private var summaryTitle: some View {
        VStack(spacing: 8) {
            Text("Key point 2 of 10")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            Text("Design is not how a thing looks, but how it\nworks")
                .font(.subheadline)
                .foregroundStyle(.appBlack)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            Text("00:28")
                .font(.caption)
                .foregroundStyle(.textSecondary)

            CustomSlider(value: .constant(0.3))

            Text("02:12")
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
    }

    private var speedButton: some View {
        Button {

        } label: {
            Text("Speed x1")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.appBlack)
                .padding(8)
                .background(.appGray, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.tapScale)
    }

    private var playerControls: some View {
        HStack(spacing: 30) {
            controlButton(icon: "backward.end.fill", action: { })

            controlButton(icon: "gobackward.5", action: { })

            controlButton(icon: "pause.fill", action: { })

            controlButton(icon: "goforward.10", action: { })

            controlButton(icon: "forward.end.fill", action: { })
        }
        .padding(.top, 20)
    }

    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(icon == "pause.fill" ? .largeTitle : .title)
                .foregroundStyle(.appBlack)
        }
        .buttonStyle(.tapScale)
    }

    private var modeToggle: some View {
        HStack {
            ForEach(DisplayMode.allCases) { displayMode in
                let isSelected = selectedDisplay == displayMode

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDisplay = displayMode
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(.appBlue)
                                .frame(width: 45, height: 45)
                                .matchedGeometryEffect(id: "toggleBackground", in: toggleAnimation)
                        }

                        Image(systemName: displayMode.icon)
                            .font(.headline)
                            .foregroundStyle(isSelected ? .appWhite : .appBlack)
                    }
                    .frame(width: 45, height: 45)
                }
                .buttonStyle(.tapScale)
            }
        }
        .padding(5)
        .background {
            Capsule()
                .fill(.appWhite)
                .strokeBorder(.appGray)
        }
        .padding(.top, 30)
    }
}

// MARK: - Preview

#Preview {
    SummaryView()
}
