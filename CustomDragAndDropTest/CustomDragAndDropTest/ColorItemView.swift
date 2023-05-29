import SwiftUI

struct ColorItemView: View {

    let backgroundColor: Color
    let isInclined: Bool

    var body: some View {
        HStack {
            Spacer()
            Text(backgroundColor.description.capitalized)
            Spacer()
        }
        .padding(.vertical, 40)
        .background(backgroundColor)
        .cornerRadius(20)
        .rotationEffect(.degrees(isInclined ? 6 : 0))
    }
}
