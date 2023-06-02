//
//  ReorderableForEach.swift
//  CustomDragAndDropTest
//
//  Created by Serhii Kostanian on 29.05.2023.
//

import SwiftUI

private class ReorderingState<Data: RandomAccessCollection>: ObservableObject {
    var reorderedItem: Data.Element?
    var reorderedItemId: Int?
    var candidateItemId: Int?
    var reorderedItemStartPosition: CGRect?
    var itemPositions: [Int: CGRect] = [:]
    var itemIdMap: [Int: String] = [:]
}

struct ReorderableForEach<Item: View, Data: RandomAccessCollection>: View where Data.Element : Identifiable {

    private var data: Data
    private var spacing: CGFloat?
    @ViewBuilder private var itemBuilder: (Data.Element) -> Item
    @ViewBuilder private var reorderedItemBuilder: (Data.Element, Bool) -> Item
    private var onMove: ((_ from: Int, _ to: Int) async -> Void)?

    @GestureState private var dragState = DragState.inactive
    @StateObject private var state = ReorderingState<Data>()

    @State private var draftData: Data

    init(
        _ data: Data,
        spacing: CGFloat? = nil,
        @ViewBuilder itemBuilder: @escaping (Data.Element) -> Item,
        @ViewBuilder reorderedItemBuilder: @escaping (Data.Element, Bool) -> Item,
        onMove: @escaping (_ from: Int, _ to: Int) async -> Void
    ) {
        self.data = data
        self.spacing = spacing
        self.itemBuilder = itemBuilder
        self.reorderedItemBuilder = reorderedItemBuilder
        self.onMove = onMove

        _draftData = State(initialValue: data)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: spacing) {
                ForEach(data) { element in
                        itemBuilder(element)
                            .opacity(dragState.isActive && element.id.hashValue == state.reorderedItemId ? 0 : 1)
                            .background(GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        state.itemPositions[element.id.hashValue] = geometry.frame(in: .named("ReorderableSpace"))
                                        state.itemIdMap[element.id.hashValue] = element.id as? String
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
                                            self.state.reorderedItem = element
                                            self.state.reorderedItemId = element.id.hashValue
                                            self.state.reorderedItemStartPosition = self.state.itemPositions[element.id.hashValue]!
                                            state = .pressing
                                            print("🚀 LONG PRESS \(self.state.reorderedItemStartPosition!)")

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
                }
            }
            .coordinateSpace(name: "ReorderableSpace")
            .opacity(dragState.isActive ? 0 : 1)

            if dragState.isActive {
                VStack(spacing: spacing) {
                    ForEach(draftData) { element in
                        itemBuilder(element)
                            .opacity(element.id.hashValue == state.reorderedItemId ? 0 : 1)
                    }
                }

                reorderedItemBuilder(state.reorderedItem!, dragState.isDragging)
                    .zIndex(1)
                    .offset(
                        x: state.reorderedItemStartPosition!.origin.x + dragState.translation.width,
                        y: state.reorderedItemStartPosition!.origin.y + dragState.translation.height
                    )
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
            y: value.location.y + state.reorderedItemStartPosition!.minY
        )

        guard let toIndex = state.itemPositions.first(where: { $0.value.contains(dragLocation) })?.key else { return }
        guard let fromIndex = state.reorderedItemId else { return }
        guard toIndex != fromIndex else { return }

        print("✅ \(dragLocation.y)")
        print("🟡 \(value.translation.height)")
        swap(fromIndex, toIndex)
    }

    

    private func swap(_ fromIndex: Int, _ toIndex: Int) {
        var map = state.itemPositions.map { ($0.value.origin.y, state.itemIdMap[$0.key]!) }
        map.sort(by: <)
        print(map.map{ "\($0.0) : \($0.1)" }.joined(separator: "\n"))

        let fromValue = state.itemPositions[fromIndex]
        let toValue = state.itemPositions[toIndex]
        state.itemPositions[fromIndex] = toValue
        state.itemPositions[toIndex] = fromValue

        state.candidateItemId = toIndex

        DispatchQueue.main.async {
            var arr = (self.draftData as! Array<Data.Element>)

            guard let from = arr.firstIndex(where: { $0.id.hashValue == fromIndex }) else { return }
            guard let to = arr.firstIndex(where: { $0.id.hashValue == toIndex }) else { return }

            arr.swapAt(from, to)
            withAnimation {
                self.draftData = arr as! Data
            }
        }

    }

    private func handleOnDragEnd() {
//        Task {
//            guard let fromIndex = state.reorderedItemId else { return }
//            guard let toIndex = state.candidateItemId else { return }
//            guard fromIndex != toIndex else { return }
//
//            await onMove?(fromIndex, toIndex)

            state.reorderedItem = nil
            state.reorderedItemId = nil
            state.reorderedItemStartPosition = nil
//        }
        print("🚀 END")
    }
}



extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: 0)
    }
}
