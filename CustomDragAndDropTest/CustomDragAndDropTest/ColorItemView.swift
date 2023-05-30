import SwiftUI

struct ColorItemView: View {

    let backgroundColor: Color
    let isInclined: Bool

    @State private var isAnimated = false

    var body: some View {
        HStack {
            Spacer()
            Text(backgroundColor.description.capitalized)
            Spacer()
        }
        .padding(.vertical, 40)
        .background(backgroundColor)
        .cornerRadius(20)
        .scaleEffect(isAnimated ? CGSize(width: 1.05, height: 1.05) : CGSize(width: 1, height: 1))
        .animation(
            .linear(duration: 0.5)
            .repeatForever(autoreverses: true),
            value: isAnimated
        )
        .rotationEffect(.degrees(isAnimated ? 6 : 0))
        .onAppear {
            if isInclined {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isAnimated = true
                }
            }
        }
    }
}
