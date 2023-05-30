import SwiftUI

struct DropViewDelegate: DropDelegate {

    let destinationItem: Color
    @Binding var colors: [Color]
    @Binding var draggedItem: Color?
    @Binding var isDropped: Bool

    func dropUpdated(info: DropInfo) -> DropProposal? {
        if isDropped {
            isDropped = false
            print("🟢 DRAG")
        }
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        isDropped = true
        print("🔴 DROP")
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem else { return }
        let fromIndex = colors.firstIndex(of: draggedItem)

        guard let fromIndex else { return }
        let toIndex = colors.firstIndex(of: destinationItem)

        guard let toIndex, fromIndex != toIndex else { return }

        // Swap Items
        withAnimation {
            self.colors.swapAt(fromIndex, toIndex)
//            self.colors.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
        }
    }
}


struct ParentDropDelegate: DropDelegate {
    @Binding var draggedItem: Color?
    @Binding var isDropped: Bool

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        isDropped = true
        print("🔴🔴 DROP")
        return true
    }
}
