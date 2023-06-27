//
//  ReorderState.swift
//  ReorderableForEachDemo
//
//  Created by Serhii Kostanian on 08.06.2023.
//

import Foundation

final class ReorderState<Data: RandomAccessCollection>: ObservableObject where Data.Element : Identifiable {
    var startElement: Data.Element?
    var startPosition: CGRect?
    var positions: [Data.Element.ID: CGRect] = [:]
    var swapStack: [Data.Element.ID] = []

    func reset() {
        startElement = nil
        startPosition = nil
        swapStack = []
    }
}
