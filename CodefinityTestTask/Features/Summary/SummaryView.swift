import ComposableArchitecture
import SwiftUI

struct SummaryView: View {
    let store: StoreOf<SummaryFeature>

    // ❓ Q9 [СПІВБЕСІДА]: selectedDisplay — локальний @State, не в TCA-стейті, а текстового
    // режиму взагалі немає. Чому стан поза стором? Чи мав би бути в State?
    @State private var selectedDisplay: DisplayMode = .audio
    @Namespace private var toggleAnimation

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
            } else if let error = store.errorMessage {
                ErrorStateView(message: error)
            } else {
                playerContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.appBackground)
        .onAppear { store.send(.onAppear) }
    }
}

// MARK: - UI Components

private extension SummaryView {
    var playerContent: some View {
        VStack(spacing: 20) {
            coverImage

            summaryTitle

            progressBar

            speedButton

            PlayerControls(
                playButtonIcon: store.playButtonIcon,
                onPrevious: { store.send(.previousChapterTapped) },
                onBackward: { store.send(.seekBackwardTapped) },
                onPlayPause: { store.send(.playPauseTapped) },
                onForward: { store.send(.seekForwardTapped) },
                onNext: { store.send(.nextChapterTapped) }
            )

            DisplayToggle(
                selectedDisplay: $selectedDisplay,
                toggleAnimation: toggleAnimation
            )
        }
        .padding()
    }

    var coverImage: some View {
        Image("bookCover")
            .resizable()
            .scaledToFill()
            .frame(width: 240, height: 350)
            .clipShape(.rect(cornerRadius: 8))
    }

    var summaryTitle: some View {
        VStack(spacing: 8) {
            Text(store.chapterLabel)
                .font(.caption)
                .bold()
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            // ❓ Q8 [СПІВБЕСІДА]: Текст саммарі захардкоджений, а в моделі Chapter немає поля
            // тексту. Чому? Як зробив би «правильно» для реальних даних на кожен key point?
            Text("Design is not how a thing looks, but how it\n works")
                .font(.subheadline)
                .foregroundStyle(.appBlack)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    var progressBar: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .trailing) {
                Text("00:00").hidden()
                Text(store.formattedCurrentTime)
            }

            CustomSlider(
                value: Binding(
                    get: { store.sliderProgress },
                    set: { store.send(.sliderProgressChanged($0)) }
                ),
                onDragEnd: { store.send(.sliderDragEnded) }
            )

            ZStack(alignment: .leading) {
                Text("00:00").hidden()
                Text(store.formattedDuration)
            }
        }
        .font(.caption)
        .foregroundStyle(.textSecondary)
        .monospacedDigit()
    }

    var speedButton: some View {
        Button {
            store.send(.speedTapped)
        } label: {
            Text(store.speedLabel)
                .font(.footnote)
                .bold()
                .foregroundStyle(.appBlack)
                .padding(8)
                .background(.appGray, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.tapScale)
    }
}

// MARK: - Preview

#Preview {
    SummaryView(
        store: Store(initialState: SummaryFeature.State()) {
            SummaryFeature()
        }
    )
}
