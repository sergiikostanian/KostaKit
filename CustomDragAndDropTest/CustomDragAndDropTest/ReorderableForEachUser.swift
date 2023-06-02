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
//        .purple, .blue, .cyan, .green, .yellow, .orange, .red
        .red, .green, .blue, .yellow
    ]

    var body: some View {
        ScrollView {
            ReorderableForEach(colors, spacing: 20) { color in

                ColorItemView(
                    backgroundColor: color,
                    isScaled: false,
                    isInclined: false
                )

            } reorderedContent: { color, isDragging in

                ColorItemView(
                    backgroundColor: color,
                    isScaled: true,
                    isInclined: isDragging
                )

            } onMove: { fromIndex, toIndex in
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
