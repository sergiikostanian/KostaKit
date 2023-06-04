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
        .red, .orange, .yellow, .green, .cyan, .blue, .purple
    ]

    var body: some View {
        ScrollView {
            ReorderableForEach(colors, spacing: 20) { color in
                ColorItemView(
                    backgroundColor: color,
                    isScaled: false,
                    isInclined: false
                )
            } reorderedContent: { color, dragState in
                ColorItemView(
                    backgroundColor: color,
                    isScaled: true,
                    isInclined: dragState.isDragging
                )
            } onMove: { fromIndex, toOffset in
                colors.move(fromOffsets: [fromIndex], toOffset: toOffset)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
        }
    }
}

struct ReorderableForEachUser_Previews: PreviewProvider {
    static var previews: some View {
        ReorderableForEachUser()
    }
}
