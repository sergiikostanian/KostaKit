import SwiftUI

struct ContentView: View {

    @State private var draggedColor: Color?
    @State private var showNotMovingItems: Bool = true
    @State private var colors: [Color] = [.purple, .blue, .cyan, .green, .yellow, .orange, .red]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {

                let _ = print("🌈 DRAW")

                ForEach(colors, id: \.self) { color in
                    ColorItemView(backgroundColor: color, isScaled: false, isInclined: color == draggedColor && !showNotMovingItems)
                        .onDrag {
                            self.draggedColor = color
                            return NSItemProvider(object: "\(color)" as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: DropViewDelegate(
                                destinationItem: color,
                                colors: $colors,
                                draggedItem: $draggedColor,
                                isDropped: $showNotMovingItems
                            )
                        )

                    Text("NOT MOVING LIST ITEM")
                        .background(color)
                        .opacity(showNotMovingItems ? 1 : 0)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color.brown)
        .onDrop(
            of: [.text],
            delegate: ParentDropDelegate(
                draggedItem: $draggedColor,
                isDropped: $showNotMovingItems
            )
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
