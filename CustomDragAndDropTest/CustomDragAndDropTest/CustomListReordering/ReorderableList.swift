import SwiftUI

class ViewModel: ObservableObject {
    var colorPosition: [String: CGRect] = [:]
    var draggedItem: String?
    var colors: [Color] = [.purple, .blue, .cyan, .green, .yellow, .orange, .red]
}

struct ReorderableList: View {

    @GestureState private var dragState = DragState.inactive

    @StateObject var viewModel = ViewModel()

    let minimumLongPressDuration = 0.5

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(Array(viewModel.colors.enumerated()), id: \.element) { index, color in
                        ZStack {
                            ColorItemView(
                                backgroundColor: color,
                                isInclined: false
                            )
                            .opacity(dragState.isActive && color.id == viewModel.draggedItem ? 0 : 1)
                            .background(GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        viewModel.colorPosition[color.id] = geometry.frame(in: .global)
                                    }
                            })

                            // Allows to have other gestures inside ScrollView
                            .onTapGesture { /* Should be empty */ }
                            .gesture(
                                LongPressGesture()
                                    .sequenced(before: DragGesture())
                                    .updating($dragState) { value, state, transaction in
                                        switch value {
                                        case .second(true, nil):
                                            // Long press begins.
                                            viewModel.draggedItem = color.id
                                            state = .pressing

                                        case .second(true, let drag):
                                            // Long press confirmed, dragging may begin.
                                            guard let drag else { return }
                                            state = .dragging(translation: drag.translation)
                                            handleOnDragChange(drag)

                                        default:
                                            // Dragging ended or the long press cancelled.
                                            state = .inactive
                                            handleOnDragEnd()
                                        }
                                    }
                                    .onEnded { value in
                                        handleOnDragEnd()
                                    }
                            )

                            if dragState.isActive, let draggedItem = viewModel.draggedItem, draggedItem == color.id {
                                ColorItemView(
                                    backgroundColor: color,
                                    isInclined: dragState.isDragging
                                )
                                .zIndex(1)
                                .offset(
                                    x: dragState.translation.width,
                                    y: dragState.translation.height
                                )
                                .scaleEffect(dragState.isActive ? CGSize(width: 1.05, height: 1.05) : CGSize(width: 1, height: 1))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.brown)
    }

    private func handleOnDragChange(_ value: DragGesture.Value) {
        swap(with:
                CGPoint(
                    x: value.location.x,
                    y: value.location.y + viewModel.colorPosition[viewModel.draggedItem!]!.origin.y
                )
        )
    }

    private func swap(with dragLocation: CGPoint) {
        guard let swapCandidate = self.viewModel.colorPosition.first(where: {$0.value.contains(dragLocation)})?.key else {
            return
        }

        let color1 = viewModel.colorPosition[swapCandidate]
        let color2 = viewModel.colorPosition[viewModel.draggedItem!]
        viewModel.colorPosition[swapCandidate] = color2
        viewModel.colorPosition[viewModel.draggedItem!] = color1

        guard let index1 = viewModel.colors.firstIndex(where: { $0.id == swapCandidate }) else { return }
        guard let index2 = viewModel.colors.firstIndex(where: { $0.id == viewModel.draggedItem }) else { return }

        withAnimation {
            self.viewModel.colors.swapAt(index1, index2)
        }
    }

    private func handleOnDragEnd() {
        withAnimation {
            viewModel.draggedItem = nil
        }
    }
}

struct ReorderableList_Previews: PreviewProvider {
    static var previews: some View {
        ReorderableList()
    }
}
