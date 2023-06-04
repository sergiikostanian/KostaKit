//
//  ReorderableForEach.swift
//  CustomDragAndDropTest
//
//  Created by Serhii Kostanian on 29.05.2023.
//

import SwiftUI

private class ReorderState<Data: RandomAccessCollection>: ObservableObject where Data.Element : Identifiable {
    var startElement: Data.Element?
    var startPosition: CGRect?
    var positions: [Data.Element.ID: CGRect] = [:]
    var swapStack: [Data.Element.ID] = []
}

struct ReorderableForEach<Item: View, Data: RandomAccessCollection>: View where Data.Element : Identifiable {

    private var data: Data
    private var spacing: CGFloat?

    @ViewBuilder private var content: (Data.Element) -> Item
    @ViewBuilder private var reorderedContent: (Data.Element, Bool) -> Item

    private var onMove: ((_ fromIndex: Int, _ toOffset: Int) -> Void)?

    @GestureState private var dragState = DragState.inactive
    @StateObject private var reorderState = ReorderState<Data>()

    init(
        _ data: Data,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Item,
        @ViewBuilder reorderedContent: @escaping (Data.Element, Bool) -> Item,
        onMove: @escaping (_ fromIndex: Int, _ toOffset: Int) -> Void
    ) {
        self.data = data
        self.spacing = spacing
        self.content = content
        self.reorderedContent = reorderedContent
        self.onMove = onMove
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            makeOriginalForEach()

            if dragState.isActive,
                let reorderElement = reorderState.startElement,
                let startPosition = reorderState.startPosition {

                makeDraftForEach()

                reorderedContent(reorderElement, dragState.isDragging)
                    .offset(
                        x: startPosition.origin.x + dragState.translation.width,
                        y: startPosition.origin.y + dragState.translation.height
                    )
            }
        }
    }

    private func makeOriginalForEach() -> some View {
        VStack(spacing: spacing) {
            ForEach(data) { element in
                    content(element)
                    .opacity(dragState.isActive && element.id == reorderState.startElement?.id ? 0 : 1)
                        .background(GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    reorderState.positions[element.id] = geometry.frame(
                                        in: .named("ReorderableSpace")
                                    )
                                }
                        })
                        // Allows to have other gestures if put inside ScrollView
                        .onTapGesture {
                            /* Should be empty */
                        }
                        .gesture(
                            makeLongPressAndDragGesture(for: element)
                        )
            }
        }
        .coordinateSpace(name: "ReorderableSpace")
        .opacity(dragState.isActive ? 0 : 1)
    }

    private func makeDraftForEach() -> some View {
        ForEach(data) { element in
            content(element)
                .opacity(element.id == reorderState.startElement?.id ? 0 : 1)
                .position(reorderState.positions[element.id]!.center)
                .animation(.default, value: reorderState.positions)
        }
    }

    private func makeLongPressAndDragGesture(for element: Data.Element) -> some Gesture {
        LongPressGesture()
            .sequenced(before: DragGesture())
            .updating($dragState) { value, state, transaction in
                switch value {
                case .second(true, nil):
                    state = .pressing
                    onLongPress(element)

                case .second(true, let drag):
                    guard let drag else { return }
                    state = .dragging(translation: drag.translation)
                    onDrag(drag)

                default:
                    state = .inactive
                    onLongPressAndDragEnd()
                }
            }
            .onEnded { value in
                onLongPressAndDragEnd()
            }
    }

    private func onLongPress(_ element: Data.Element) {
        reorderState.startElement = element
        reorderState.startPosition = reorderState.positions[element.id]
    }

    private func onDrag(_ value: DragGesture.Value) {
        Task(priority: .userInitiated) {
            let dragLocation = CGPoint(
                x: value.location.x,
                y: value.location.y + reorderState.startPosition!.minY
            )

            guard let toIndex = reorderState.positions.first(where: { $0.value.contains(dragLocation) })?.key else { return }
            guard let fromIndex = reorderState.startElement?.id else { return }
            guard toIndex != fromIndex else { return }

            swapElements(fromIndex, toIndex)
        }
    }

    private func swapElements(_ fromIndex: Data.Element.ID, _ toIndex: Data.Element.ID) {
        let fromValue = reorderState.positions[fromIndex]
        let toValue = reorderState.positions[toIndex]
        reorderState.positions[fromIndex] = toValue
        reorderState.positions[toIndex] = fromValue

        guard let endElement = data.first(where: { $0.id == toIndex }) else { return }

        if reorderState.swapStack.last == endElement.id {
            reorderState.swapStack.removeLast()
        } else {
            reorderState.swapStack.append(endElement.id)
        }
    }

    private func onLongPressAndDragEnd() {
        Task(priority: .userInitiated) {
            defer {
                reorderState.startElement = nil
                reorderState.startPosition = nil
                reorderState.swapStack = []
            }

            guard !reorderState.swapStack.isEmpty else { return }

            guard let startElementId = reorderState.startElement?.id else { return }
            guard let endElementId = reorderState.swapStack.last else { return }

            guard let fromIndex = data.firstIndex(where: {$0.id == startElementId}) as? Int else { return }
            guard var toOffset =  data.firstIndex(where: {$0.id == endElementId}) as? Int else { return }

            // Read this: https://developer.apple.com/documentation/swift/mutablecollection/move(fromoffsets:tooffset:)
            // and this: https://stackoverflow.com/questions/69321574/swift-array-move-function-doesnt-behave-as-you-would-expect-why
            // to understand/recall the concept of moving items inside a Collection
            // to the specified destination offset
            if fromIndex < toOffset {
                toOffset += 1
            }

            onMove?(fromIndex, toOffset)
        }
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(
            x: origin.x + width/2,
            y: origin.y + height/2
        )
    }
}
