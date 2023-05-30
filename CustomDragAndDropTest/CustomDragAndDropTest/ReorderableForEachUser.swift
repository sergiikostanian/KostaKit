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
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ReorderableForEach(colors) { color in

                    ColorItemView(
                        backgroundColor: color,
                        isInclined: false
                    )

                } reorderedItemBuilder: { color in

                    ColorItemView(
                        backgroundColor: color,
                        isInclined: true
                    )

                } onMove: { from, to in

                    guard let fromIndex = colors.firstIndex(where: { $0.id.hashValue == from }) else { return }
                    guard let toIndex = colors.firstIndex(where: { $0.id.hashValue == to }) else { return }
                    print("🌈 swap \(fromIndex) with \(toIndex)")
//                    withAnimation {
                        colors.swapAt(fromIndex, toIndex)
//                    }
                }
            }
            .padding()
        }
    }
}

struct ReorderableForEachUser_Previews: PreviewProvider {
    static var previews: some View {
        ReorderableForEachUser()
    }
}
