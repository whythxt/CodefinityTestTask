import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let thumbSize: CGFloat = 16
            let usableWidth = trackWidth - thumbSize
            let fillWidth = usableWidth * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.15))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.appBlue)
                    .frame(width: fillWidth + thumbSize / 2, height: 4)

                Circle()
                    .fill(Color.appBlue)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: fillWidth)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let newValue = Double(gesture.location.x / usableWidth) * (range.upperBound - range.lowerBound) + range.lowerBound
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                            }
                    )
            }
        }
        .frame(height: 16)
    }
}

#Preview {
    CustomSlider(value: .constant(0.0))
        .padding()
}
