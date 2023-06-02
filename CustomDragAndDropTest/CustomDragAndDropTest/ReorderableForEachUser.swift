//
//  ReorderableForEachUser.swift
//  CustomDragAndDropTest
//
//  Created by Serhii Kostanian on 29.05.2023.
//

import SwiftUI

extension Color: Identifiable {
    public var id: String { description }
}


struct ReorderableForEachUser: View {

    @State var colors: [Color] = [
        .purple, .blue, .cyan, .green, .yellow, .orange, .red
//        .red, .green, .blue, .yellow
    ]

    var body: some View {
        ScrollView {
            ReorderableForEach(colors, spacing: 20) { color in

                ColorItemView(
                    backgroundColor: color,
                    isScaled: false,
                    isInclined: false
                )

            } reorderedItemBuilder: { color, isDragging in

                ColorItemView(
                    backgroundColor: color,
                    isScaled: true,
                    isInclined: isDragging
                )

            } onMove: { from, to in

                guard let fromIndex = colors.firstIndex(where: { $0.id.hashValue == from }) else { return }
                guard let toIndex = colors.firstIndex(where: { $0.id.hashValue == to }) else { return }
                print("🌈 swap \(fromIndex) with \(toIndex)")
                colors.swapAt(fromIndex, toIndex)

            }
        }
    }
}

struct ReorderableForEachUser_Previews: PreviewProvider {
    static var previews: some View {
        ReorderableForEachUser()
    }
}
