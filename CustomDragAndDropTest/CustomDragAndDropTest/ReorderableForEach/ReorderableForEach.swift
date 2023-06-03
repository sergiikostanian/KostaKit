//
//  ReorderableForEach.swift
//  CustomDragAndDropTest
//
//  Created by Serhii Kostanian on 29.05.2023.
//

import SwiftUI

private class ReorderState<Data: RandomAccessCollection>: ObservableObject where Data.Element : Identifiable {
    var startElement: Data.Element?
    var endElement: Data.Element?
    var startPosition: CGRect?
    var positions: [Data.Element.ID: CGRect] = [:]
}

struct ReorderableForEach<Item: View, Data: RandomAccessCollection>: View where Data.Element : Identifiable {

    private var data: Data
    private var spacing: CGFloat?

    @ViewBuilder private var content: (Data.Element) -> Item
    @ViewBuilder private var reorderedContent: (Data.Element, Bool) -> Item

    private var onMove: ((_ from: Data.Index, _ to: Data.Index) async -> Void)?

    @GestureState private var dragState = DragState.inactive
    @StateObject private var reorderState = ReorderState<Data>()

    init(
        _ data: Data,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Item,
        @ViewBuilder reorderedContent: @escaping (Data.Element, Bool) -> Item,
        onMove: @escaping (_ from: Data.Index, _ to: Data.Index) async -> Void
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
        self.reorderState.startElement = element
        self.reorderState.startPosition = self.reorderState.positions[element.id]!
        print("🚀 LONG PRESS")
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

            print("✅ \(dragLocation.y)")

            swap(fromIndex, toIndex)
        }
    }

    private func swap(_ fromIndex: Data.Element.ID, _ toIndex: Data.Element.ID) {
        let fromValue = reorderState.positions[fromIndex]
        let toValue = reorderState.positions[toIndex]
        reorderState.positions[fromIndex] = toValue
        reorderState.positions[toIndex] = fromValue
        reorderState.endElement = data.first(where: { $0.id == toIndex })
    }

    private func onLongPressAndDragEnd() {
        Task {
            guard let startElement = reorderState.startElement else { return }
            guard let endElement = reorderState.endElement else { return }
            guard startElement.id != endElement.id else { return }

            guard let fromIndex = data.firstIndex(where: {$0.id == startElement.id}) else { return }
            guard let toIndex =  data.firstIndex(where: {$0.id == endElement.id}) else { return }

            await onMove?(fromIndex, toIndex)

            reorderState.startElement = nil
            reorderState.endElement = nil
            reorderState.startPosition = nil
        }
        print("🚀 END")
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: origin.x + width/2, y: origin.y + height/2)
    }
}
