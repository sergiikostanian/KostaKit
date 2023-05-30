//
//  ReorderableForEach.swift
//  CustomDragAndDropTest
//
//  Created by Serhii Kostanian on 29.05.2023.
//

import SwiftUI

private class ReorderingState: ObservableObject  {
    var reorderedItemId: Int?
    var itemPositions: [Int: CGRect] = [:]
}

struct ReorderableForEach<Item: View, Data: RandomAccessCollection>: View where Data.Element : Identifiable {

    private var data: Data
    @ViewBuilder private var itemBuilder: (Data.Element) -> Item
    @ViewBuilder private var reorderedItemBuilder: (Data.Element) -> Item
    private var onMove: ((_ from: Int, _ to: Int) async -> Void)?

    @GestureState private var dragState = DragState.inactive
    @StateObject private var state = ReorderingState()

    init(
        _ data: Data,
        @ViewBuilder itemBuilder: @escaping (Data.Element) -> Item,
        @ViewBuilder reorderedItemBuilder: @escaping (Data.Element) -> Item,
        onMove: @escaping (_ from: Int, _ to: Int) async -> Void
    ) {
        self.data = data
        self.itemBuilder = itemBuilder
        self.reorderedItemBuilder = reorderedItemBuilder
        self.onMove = onMove
    }

    var body: some View {
        ForEach(data) { element in
            ZStack {

                itemBuilder(element)
                    .opacity(dragState.isActive && element.id.hashValue == state.reorderedItemId ? 0 : 1)
                    .background(GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.itemPositions[element.id.hashValue] = geometry.frame(in: .global)
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
                                self.state.reorderedItemId = element.id.hashValue
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

                if showElementAsReordered(element) {
                    reorderedItemBuilder(element)
                    .zIndex(1)
                    .offset(
                        x: dragState.translation.width,
                        y: dragState.translation.height
                    )
                }
            }
        }
    }

    private func showElementAsReordered(_ element: Data.Element) -> Bool {
        if dragState.isActive,
           let reorderedItemId = state.reorderedItemId,
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
    }

    private func swap(_ fromIndex: Int, _ toIndex: Int) {
        let fromValue = state.itemPositions[fromIndex]
        let toValue = state.itemPositions[toIndex]
        state.itemPositions[fromIndex] = toValue
        state.itemPositions[toIndex] = fromValue

        Task {
            await onMove?(fromIndex, toIndex)
        }
    }

    private func handleOnDragEnd() {
        state.reorderedItemId = nil
    }
}
