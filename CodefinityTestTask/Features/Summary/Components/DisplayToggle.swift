import SwiftUI

struct DisplayToggle: View {
    @Binding var selectedDisplay: DisplayMode
    var toggleAnimation: Namespace.ID

    var body: some View {
        HStack {
            ForEach(DisplayMode.allCases) { mode in
                let isSelected = selectedDisplay == mode

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDisplay = mode
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(.appBlue)
                                .frame(width: 45, height: 45)
                                .matchedGeometryEffect(id: "toggleBackground", in: toggleAnimation)
                        }
                        Image(systemName: mode.icon)
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
