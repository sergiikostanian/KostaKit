//
//  DraggableCircle.swift
//  CustomDragAndDropTest
//
//  Created by Serhii Kostanian on 30.05.2023.
//

import SwiftUI

struct DraggableCircle: View {

    enum DragState {
        case inactive
        case pressing
        case dragging(translation: CGSize)

        var translation: CGSize {
            switch self {
            case .inactive, .pressing:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }

        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .pressing, .dragging:
                return true
            }
        }

        var isDragging: Bool {
            switch self {
            case .inactive, .pressing:
                return false
            case .dragging:
                return true
            }
        }

        var isPressing: Bool {
            switch self {
            case .inactive:
                return false
            case .pressing:
                return true
            case .dragging:
                return false
            }
        }
    }
//    @GestureState private var dragState = DragState.inactive
//    @GestureState private var longPressState: Bool = false
    @State private var longPressState: Bool = false

    var body: some View {
//            let longPressDrag = LongPressGesture(minimumDuration: minimumLongPressDuration)
//                .sequenced(before: DragGesture())
//                .updating($dragState) { value, state, transaction in
//                    switch value {
//                    // Long press begins.
//                    case .first(true):
//                        state = .pressing
//
//                    // Long press confirmed, dragging may begin.
//                    case .second(true, let drag):
//                        state = .dragging(translation: drag?.translation ?? .zero)
//
//                    // Dragging ended or the long press cancelled.
//                    default:
//                        state = .inactive
//                    }
//                }
//                .onEnded { value in
//                }

        ZStack {
            let _ = print("🔴 MAIN")

            OverlayCircle()
        }
    }
}


struct OverlayCircle: View {
    @GestureState var dragState = DraggableCircle.DragState.pressing

    var body: some View {
        let _ = print("🟢 OVERLAY")

        Circle()
            .fill(dragState.isPressing ? Color.red : Color.brown )
            .frame(width: 110, height: 110, alignment: .center)
            .offset(
                x: dragState.translation.width,
                y: dragState.translation.height
            )
            .shadow(radius: 8)
            .gesture(LongPressGesture(minimumDuration: 0.5)
                .sequenced(before: DragGesture())
                .updating($dragState) { value, state, transaction in
                    switch value {
                    // Long press begins.
                    case .first(true):
                        state = .pressing

                    // Long press confirmed, dragging may begin.
                    case .second(true, let drag):
                        state = .dragging(translation: drag?.translation ?? .zero)

                    // Dragging ended or the long press cancelled.
                    default:
                        state = .inactive
                    }
                }
                .onEnded { value in
                }
            )
    }
}
