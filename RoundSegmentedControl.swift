//
//  RoundSegmentedControl.swift
//  Segmented
//
//  Created by Sergii Kostanian on 01.10.2019.
//  Copyright © 2019 Sergii Kostanian. All rights reserved.
//

import UIKit
import Combine

/**
 The segmented control that is more customizable than the standard one.
 */
public final class RoundSegmentedControl: UIControl {

    // MARK: - Public properties

    /// An array of String objects for segment titles. It __MUST__ have more than 1 object otherwise this control doesn't make sense.
    public var items: [String] = ["First", "Second"] {
        didSet { didSetItems(items, oldValue: oldValue) }
    }

    /// The index number identifying the selected segment.
    @Published
    public var selectedIndex: Int = 0 {
        didSet { didSetSelectedIndex(selectedIndex, oldValue: oldValue) }
    }

    /// The corner radius of the edges of the whole control and the selection layer.
    public var cornerRadius: CGFloat = 8 {
        didSet { didSetCornerRadius(cornerRadius) }
    }

    /// The border width between the controls edge and the selection layer.
    public var borderWidth: CGFloat = 2 {
        didSet { didSetBorderWidth(borderWidth) }
    }

    /// The color of the selection layer.
    public var selectionColor: UIColor = .black {
        didSet { didSetSelectionColor(selectionColor) }
    }

    /// The color of the selected segment title.
    public var selectedTitleColor: UIColor = .white {
        didSet { didSetSelectedTitleColor(selectedTitleColor) }
    }

    /// The color of  unselected segments title.
    public var unselectedTitleColor: UIColor = .black {
        didSet { didSetUnselectedTitleColor(unselectedTitleColor) }
    }

    /// Segments title font.
    public var font: UIFont = .systemFont(ofSize: 10) {
        didSet { didSetFont(font) }
    }

    public override var backgroundColor: UIColor? {
        didSet { didSetBackgroundColor(backgroundColor) }
    }

    // MARK: - Private properies
    private var itemsStackView = UIStackView()
    private let selectionLayer = CALayer()

    // MARK: - Lifecycle
    public init(items: [String]) {
        super.init(frame: .zero)
        self.items = items
        self.setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutSelectionLayer(for: selectedIndex)
        let sc = UISegmentedControl(items: [])
        sc.selectedSegmentIndex = 2
    }
}

// MARK: - Update methods
private extension RoundSegmentedControl {

    func didSetSelectedIndex(_ value: Int, oldValue: Int) {
        guard value != oldValue else { return }
        guard value >= 0 && value < itemsStackView.arrangedSubviews.count else { return }

        if let button = itemsStackView.arrangedSubviews[oldValue] as? UIButton {
            button.isSelected = false
        }
        if let button = itemsStackView.arrangedSubviews[value] as? UIButton {
            button.isSelected = true
        }
        layoutSelectionLayer(for: value)
        sendActions(for: .valueChanged)
    }

    func didSetItems(_ value: [String], oldValue: [String]) {
        guard value.count > 1 else {
            items = oldValue
            return
        }
        selectedIndex = 0
        reloadSegments()
    }

    func didSetCornerRadius(_ value: CGFloat) {
        layer.cornerRadius = value
        selectionLayer.cornerRadius = value - borderWidth
    }

    func didSetSelectionColor(_ value: UIColor) {
        selectionLayer.backgroundColor = value.cgColor
    }

    func didSetSelectedTitleColor(_ value: UIColor) {
        itemsStackView.arrangedSubviews.forEach { view in
            guard let button  = view as? UIButton else { return }
            button.setTitleColor(value, for: .selected)
        }
    }

    func didSetUnselectedTitleColor(_ value: UIColor) {
        itemsStackView.arrangedSubviews.forEach { view in
            guard let button  = view as? UIButton else { return }
            button.setTitleColor(value, for: .normal)
        }
    }

    func didSetFont(_ value: UIFont) {
        itemsStackView.arrangedSubviews.forEach { view in
            guard let button  = view as? UIButton else { return }
            button.titleLabel?.font = value
        }
    }

    func didSetBorderWidth(_ value: CGFloat) {
        layer.borderWidth = value
        layoutSelectionLayer(for: selectedIndex)
    }

    func didSetBackgroundColor(_ value: UIColor?) {
        super.backgroundColor = value
        layer.borderColor = value?.cgColor
    }
}

// MARK: - Private methods
private extension RoundSegmentedControl {

    func setup() {
        setupSelectionLayer()
        setupItemsStackView()
        reloadSegments()
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = backgroundColor?.cgColor
        clipsToBounds = true
    }

    func setupSelectionLayer() {
        selectionLayer.cornerRadius = cornerRadius - borderWidth
        selectionLayer.backgroundColor = selectionColor.cgColor
        selectionLayer.masksToBounds = true
        layer.addSublayer(selectionLayer)

    }
    func setupItemsStackView() {
        itemsStackView.layer.cornerRadius = cornerRadius
        itemsStackView.backgroundColor = .clear
        itemsStackView.distribution = .fillEqually
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(itemsStackView)

        NSLayoutConstraint.activate([
            itemsStackView.topAnchor.constraint(equalTo: topAnchor),
            itemsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: itemsStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: itemsStackView.bottomAnchor)
        ])
    }

    func reloadSegments() {
        itemsStackView.arrangedSubviews.forEach({ itemsStackView.removeArrangedSubview($0) })
        for (index, title) in items.enumerated() {
            let button = makeItemButton(for: index, with: title)
            itemsStackView.addArrangedSubview(button)
            if index == selectedIndex {
                button.isSelected = true
            }
        }
    }

    func makeItemButton(for index: Int, with title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitleColor(unselectedTitleColor, for: .normal)
        button.setTitleColor(selectedTitleColor, for: .selected)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = font
        button.tag = index
        button.addTarget(self, action: #selector(didTapItemButton(_:)), for: .touchUpInside)
        addSubview(button)
        return button
    }

    func layoutSelectionLayer(for index: Int) {
        let segmentWidth = bounds.width / CGFloat(itemsStackView.arrangedSubviews.count)
        let offset = CGFloat(index) * segmentWidth + borderWidth
        selectionLayer.frame = CGRect(x: offset,
                                      y: borderWidth,
                                      width: segmentWidth - (borderWidth * 2),
                                      height: bounds.height - (borderWidth * 2))
    }

    @objc
    func didTapItemButton(_ sender: UIButton) {
        selectedIndex = sender.tag
    }
}
