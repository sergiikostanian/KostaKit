//
//  ReorderableForEach.swift
//  CustomDragAndDropTest
//
//  Created by Serhii Kostanian on 29.05.2023.
//

import SwiftUI

private class ReorderingState<Data: RandomAccessCollection>: ObservableObject  {
    var reorderedElement: Data.Element?
    var reorderedItemId: Int?
    var itemPositions: [Int: CGRect] = [:]
    var canSwap: Bool = true
    var translation: CGSize = .zero
}

// TODO: TRY TO SEPARATE THE LONG PRESS FROM THE DRAG
// LONG PRESS - ON THE FOREACH ITEM
// DRAG - ON THE REORDERED ITEM THAT WE ADD ONLY FOR DRAGGING VISIBILITY

struct ReorderableForEach2<Item: View, Data: RandomAccessCollection>: View where Data.Element : Identifiable {

    private var data: Data
    @ViewBuilder private var itemBuilder: (Data.Element) -> Item
    @ViewBuilder private var reorderedItemBuilder: (Data.Element) -> Item
    private var onMove: ((_ from: Int, _ to: Int) -> Void)?

    @StateObject private var state = ReorderingState<Data>()
    @State var reorderedElementId: Int?

    init(
        _ data: Data,
        @ViewBuilder itemBuilder: @escaping (Data.Element) -> Item,
        @ViewBuilder reorderedItemBuilder: @escaping (Data.Element) -> Item,
        onMove: @escaping (_ from: Int, _ to: Int) -> Void
    ) {
        self.data = data
        self.itemBuilder = itemBuilder
        self.reorderedItemBuilder = reorderedItemBuilder
        self.onMove = onMove
    }

    var body: some View {
        let _ = print("🌈 DRAW")

        ForEach(data) { element in
            ZStack {

                DataElementWrapper(
                    state: state,
                    element: element,
                    content: itemBuilder(element),
                    onLongPress: {
                        reorderedElementId = element.id.hashValue
                    },
                    onDrag: { dragValue in
                        handleOnDragChange(dragValue)
                    },
                    onDragEnd: {
                        reorderedElementId = nil
                    }
                )
                .background(GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            state.itemPositions[element.id.hashValue] = geometry.frame(in: .global)
                        }
                })

                if reorderedElementId == element.id.hashValue {
                    reorderedItemBuilder(element)
                        .zIndex(1)
                        .offset(
                            x: state.translation.width,
                            y: state.translation.height
                        )
//                        .opacity(0)
                }
            }
        }
    }

    private func showElementAsReordered(_ element: Data.Element) -> Bool {
//        if dragState.isActive,
//           let reorderedItemId = state.reorderedItemId,
//           reorderedItemId == element.id.hashValue {
        if let reorderedItemId = state.reorderedItemId,
           reorderedItemId == element.id.hashValue {
            return true
        } else {
            return false
        }
    }

    private func handleOnDragChange(_ value: DragGesture.Value) {
        guard let reorderedItemId = state.reorderedItemId else { return }

        let dragLocation = CGPoint(
            x: value.location.x,
            y: value.location.y + state.itemPositions[reorderedItemId]!.origin.y
        )

        guard let toIndex = state.itemPositions.first(where: { $0.value.contains(dragLocation) })?.key else { return }
        guard let fromIndex = state.reorderedItemId else { return }
        guard toIndex != fromIndex else { return }

        swap(fromIndex, toIndex)

//        if state.canSwap {
//            swap(fromIndex, toIndex)
//            state.canSwap = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.state.canSwap = true
//            }
//        }
    }

//    private func swap(_ fromIndex: Int, _ toIndex: Int) {
//        Task {
//            let fromValue = state.itemPositions[fromIndex]
//            let toValue = state.itemPositions[toIndex]
//            state.itemPositions[fromIndex] = toValue
//            state.itemPositions[toIndex] = fromValue
//            await onMove?(fromIndex, toIndex)
//        }
//    }

    private func swap(_ fromIndex: Int, _ toIndex: Int) {
//        let fromValue = state.itemPositions[fromIndex]
//        let toValue = state.itemPositions[toIndex]
//        state.itemPositions[fromIndex] = toValue
//        state.itemPositions[toIndex] = fromValue

        DispatchQueue.main.async {
            self.onMove?(fromIndex, toIndex)
        }
    }

    private func handleOnDragEnd() {
        state.reorderedItemId = nil
        state.reorderedElement = nil
    }
}


private struct DataElementWrapper<Content, Data>: View where
    Content: View,
    Data: RandomAccessCollection,
    Data.Element : Identifiable
{

    @GestureState private var dragState = DragState.inactive

    var state: ReorderingState<Data>
    var element: Data.Element
    var content: Content
    var onLongPress: () -> Void
    var onDrag: (DragGesture.Value) -> Void
    var onDragEnd: () -> Void

    init(
        state: ReorderingState<Data>,
        element: Data.Element,
        content: Content,
        onLongPress: @escaping () -> Void,
        onDrag: @escaping (DragGesture.Value) -> Void,
        onDragEnd: @escaping () -> Void
    ) {
        self.state = state
        self.element = element
        self.content = content
        self.onLongPress = onLongPress
        self.onDrag = onDrag
        self.onDragEnd = onDragEnd
    }

    var body: some View {
        content
            .opacity(state.reorderedElement != nil && element.id == state.reorderedElement?.id ? 0 : 1)
        // Allows to have other gestures inside ScrollView
            .onTapGesture { /* Should be empty */ }
            .gesture(
                LongPressGesture()
                    .sequenced(before: DragGesture())
                    .updating($dragState) { value, state, transaction in
                        switch value {
                        case .second(true, nil):
                            // Long press begins.
                            self.state.reorderedItemId = element.id.hashValue
                            self.state.reorderedElement = element
                            state = .pressing
                            DispatchQueue.main.async {
                                onLongPress()
                            }

                        case .second(true, let drag):
                            // Long press confirmed, dragging may begin.
                            guard let drag else { return }
                            state = .dragging(translation: drag.translation)
                            self.state.translation = drag.translation
//                            DispatchQueue.main.async {
                                onDrag(drag)
//                            }

                        default:
                            // Dragging ended or the long press cancelled.
                            state = .inactive
                            self.state.translation = .zero
                            DispatchQueue.main.async {
                                onDragEnd()
                            }
                        }
                    }
                    .onEnded { value in
                        self.state.translation = .zero
                        DispatchQueue.main.async {
                            onDragEnd()
                        }
                    }
            )
    }
}
