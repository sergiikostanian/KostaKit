import SwiftUI

struct ColorItemView: View {

    let backgroundColor: Color
    let isScaled: Bool
    let isInclined: Bool

    @State private var isAnimated = false

    var body: some View {
        HStack {
            Spacer()
            Text(backgroundColor.description.capitalized)
            Spacer()
        }
        .frame(height: 80)
        .background(backgroundColor)
        .cornerRadius(20)
        .scaleEffect(isAnimated ? CGSize(width: 1.05, height: 1.05) : CGSize(width: 1, height: 1))
        .animation(
            .linear(duration: 0.5)
            .repeatForever(autoreverses: true),
            value: isAnimated
        )
        .rotationEffect(.degrees(isInclined ? 6 : 0))
        .opacity(isScaled ? 0.9 : 1)
        .onAppear {
            if isScaled {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isAnimated = true
                }
            }
        }
    }
}
