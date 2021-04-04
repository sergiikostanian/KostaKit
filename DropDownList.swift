//
//  DropDownList.swift
//  Segmented
//
//  Created by Serhii Kostanian on 19.02.2021.
//  Copyright © 2021 Sergii Kostanian. All rights reserved.
//

import UIKit
import Combine

/**
 The drop down list control that could be shown inside any view with a dimming effect.
 - Note: Use `tintColor` to set selection color.
 */
public final class DropDownList: UIControl {

    private enum Defaults {
        static let animationDuration: TimeInterval = 0.3
        static let listWidth: CGFloat = 150
        static let dimmColor = UIColor.black.withAlphaComponent(0.15)
        static let cornerRadius: CGFloat = 16

        enum Item {
            static let sideInset: CGFloat = 20
            static let height: CGFloat = 44
        }

        enum Shadow {
            static let opacity: Float = 0.2
            static let radius: CGFloat = 12
            static let offset = CGSize(width: 0, height: 4)
        }
    }

    // MARK: - Private properties

    private let items: [String]

    private var shadowView = UIView()
    private var itemsContainer = UIView()
    private var itemsStackView = UIStackView()
    private var itemsTopConstraint: NSLayoutConstraint!
    private var itemsLeftConstraint: NSLayoutConstraint!
    private var itemsWidthConstraint: NSLayoutConstraint!
    private var itemsHidingConstraint: NSLayoutConstraint!

    // MARK: - Public properties

    /// The index number identifying the selected item.
    @Published
    public var selectedIndex: Int? {
        didSet { didSetSelectedIndex(selectedIndex, oldValue: oldValue) }
    }

    /// The width of the list.
    public var listWidth: CGFloat = Defaults.listWidth {
        didSet { didSetListWidth(listWidth) }
    }

    /// The dropping point of the list (the top left point).
    public var droppingPoint: CGPoint = .zero {
        didSet { didSetDroppingPoint(droppingPoint) }
    }

    /// The font of the list items.
    public var font: UIFont = .systemFont(ofSize: 14) {
        didSet { didSetFont(font) }
    }

    /// The text color of the list items.
    public var textColor: UIColor = .black {
        didSet { didSetTextColor(textColor) }
    }

    // MARK: - Lifecycle
    init(items: [String]) {
        self.items = items
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public methods
public extension DropDownList {

    /// Show drop down list inside the specified view.
    /// - Parameter view: The view in which drop down list will be shown.
    func show(in view: UIView) {
        view.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        layoutIfNeeded()

        backgroundColor = .clear
        itemsHidingConstraint.isActive = false
        UIView.animate(withDuration: Defaults.animationDuration) {
            self.backgroundColor = Defaults.dimmColor
            self.layoutIfNeeded()
        }
    }

    /// Hides drop down list and removes it from it's superview.
    @objc
    func hide() {
        itemsHidingConstraint.isActive = true
        UIView.animate(withDuration: Defaults.animationDuration, animations: {
            self.backgroundColor = .clear
            self.layoutIfNeeded()
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}

// MARK: - Update methods
private extension DropDownList {

    func didSetSelectedIndex(_ value: Int?, oldValue: Int?) {
        guard value != oldValue else { return }

        if let oldIndex = oldValue,
           itemsStackView.arrangedSubviews.count > oldIndex,
           let button = itemsStackView.arrangedSubviews[oldIndex] as? UIButton {
            button.backgroundColor = nil
        }

        if let newIndex = value,
           itemsStackView.arrangedSubviews.count > newIndex,
           let button = itemsStackView.arrangedSubviews[newIndex] as? UIButton {
            button.backgroundColor = tintColor
        }
    }

    func didSetListWidth(_ value: CGFloat) {
        itemsWidthConstraint?.constant = value
    }

    func didSetDroppingPoint(_ value: CGPoint) {
        itemsTopConstraint?.constant = value.y
        itemsLeftConstraint?.constant = value.x
    }

    func didSetFont(_ value: UIFont) {
        itemsStackView.arrangedSubviews.forEach { view in
            guard let button  = view as? UIButton else { return }
            button.titleLabel?.font = value
        }
    }

    func didSetTextColor(_ value: UIColor) {
        itemsStackView.arrangedSubviews.forEach { view in
            guard let button  = view as? UIButton else { return }
            button.setTitleColor(value, for: .normal)
        }
    }
}

// MARK: - Private methods
private extension DropDownList {

    func setup() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hide))
        addGestureRecognizer(tapGesture)

        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        setupItemsContainer()
        setupItemsStackView()
        setupShadowView()
    }

    func setupItemsContainer() {
        itemsContainer.clipsToBounds = true
        itemsContainer.layer.cornerRadius = Defaults.cornerRadius
        itemsContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(itemsContainer)

        itemsTopConstraint = itemsContainer.topAnchor.constraint(equalTo: topAnchor, constant: droppingPoint.y)
        itemsLeftConstraint = itemsContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: droppingPoint.x)
        itemsWidthConstraint = itemsContainer.widthAnchor.constraint(equalToConstant: listWidth)
        itemsHidingConstraint = itemsContainer.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            itemsTopConstraint,
            itemsLeftConstraint,
            itemsWidthConstraint,
            itemsHidingConstraint
        ])
    }

    func setupItemsStackView() {
        itemsStackView.layer.cornerRadius = Defaults.cornerRadius
        itemsStackView.backgroundColor = .white
        itemsStackView.axis = .vertical
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false
        itemsContainer.addSubview(itemsStackView)

        let bottomConstraint = itemsContainer.bottomAnchor.constraint(equalTo: itemsStackView.bottomAnchor)
        bottomConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            itemsStackView.topAnchor.constraint(equalTo: itemsContainer.topAnchor),
            itemsStackView.leadingAnchor.constraint(equalTo: itemsContainer.leadingAnchor),
            itemsContainer.trailingAnchor.constraint(equalTo: itemsStackView.trailingAnchor),
            bottomConstraint
        ])

        for (index, title) in items.enumerated() {
            let button = makeItemButton(for: index, with: title)
            itemsStackView.addArrangedSubview(button)
        }
    }

    func setupShadowView() {
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = Defaults.Shadow.opacity
        shadowView.layer.shadowRadius = Defaults.Shadow.radius
        shadowView.layer.shadowOffset = Defaults.Shadow.offset
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(shadowView, belowSubview: itemsContainer)

        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: itemsContainer.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: itemsContainer.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: itemsContainer.trailingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: itemsContainer.bottomAnchor)
        ])
    }

    func makeItemButton(for index: Int, with title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets.left = Defaults.Item.sideInset
        button.setTitle(title, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = font
        button.tag = index
        button.heightAnchor.constraint(equalToConstant: Defaults.Item.height).isActive = true
        button.addTarget(self, action: #selector(didTapItemButton(_:)), for: .touchUpInside)
        return button
    }

    @objc func didTapItemButton(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
    }
}
