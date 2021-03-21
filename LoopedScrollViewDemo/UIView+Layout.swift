//
//  UIView+Layout.swift
//
//  Created by Serhii Kostanian on 19.03.2021.
//  Copyright © 2021 Sergii Kostanian. All rights reserved.
//

import UIKit

public extension UIView {

    /// Adds subview along with every edge constraints with zero insets.
    ///
    /// - Parameter view: Subview to add.
    func addSubviewAndStretchToFill(_ view: UIView) {
        addSubviewAndStretch(view, edgeInsets: .zero)
    }

    /// Adds subview along with every edge constraints with specified edge insets.
    ///
    /// - Parameters:
    ///   - view: Subview to add.
    ///   - edgeInsets: Edge insets that will be applied to edge constraints constants.
    func addSubviewAndStretch(_ view: UIView, edgeInsets: UIEdgeInsets) {
        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor, constant: edgeInsets.top),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: edgeInsets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: edgeInsets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: edgeInsets.bottom)
        ])
    }
}
