//
//  LoopedScrollView.swift
//
//  Created by Serhii Kostanian on 19.03.2021.
//  Copyright © 2021 Sergii Kostanian. All rights reserved.
//

import UIKit

/**
 The methods adopted by the object you use to manage data and provide items for a looped scroll view.
 */
public protocol LoopedScrollViewDataSource {
    /// Asks the data source to return the number of items in the looped scroll view.
    func numberOfItems(in view: LoopedScrollView) -> Int
    /// Asks the data source for a view to insert in a particular location of the looped scroll view.
    func loopedScrollView(_ view: LoopedScrollView, itemAt index: Int) -> UIView
}

/**
 A paged scroll view that loops its items.

 Inspired by [this idea](https://github.com/aybekckaya/InfiniteScrollView).
 */
public final class LoopedScrollView: UIView {

    // MARK: - Public properties

    /// The object that acts as the data source of the looped scroll view.
    public var dataSource: LoopedScrollViewDataSource?

    // MARK: - Private properties
    private var isTurningPage = false
    private var numberOfItems: Int = 0
    private var currentPage: Int = 0
    private var stackWidthConstraint: NSLayoutConstraint?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    // MARK: - Lifecycle
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        stackWidthConstraint?.constant = CGFloat(numberOfItems + 2) * bounds.size.width
        scrollView.contentOffset.x = bounds.size.width * CGFloat(currentPage)
    }
}

// MARK: - Public methods
public extension LoopedScrollView {

    /// Reloads the items of the looped scroll view.
    func reloadData() {
        guard let dataSource = dataSource else { return }

        numberOfItems = dataSource.numberOfItems(in: self)

        guard numberOfItems > 0 else { return }
        guard numberOfItems > 1 else {
            let firstItem = dataSource.loopedScrollView(self, itemAt: 0)
            addPage(firstItem)
            scrollView.isScrollEnabled = false
            return
        }

        let lastItem = dataSource.loopedScrollView(self, itemAt: numberOfItems - 1)
        addPage(lastItem)

        for index in 0..<self.numberOfItems {
            let item = dataSource.loopedScrollView(self, itemAt: index)
            addPage(item)
        }

        let firstItem = dataSource.loopedScrollView(self, itemAt: 0)
        addPage(firstItem)

        stackWidthConstraint?.constant = CGFloat(numberOfItems + 2) * bounds.size.width
        scrollView.contentOffset.x = bounds.size.width
        currentPage = 1
    }

    /// Scrolls to the next page.
    func scrollToNextPage() {
        guard !isTurningPage else { return }
        isTurningPage = true

        let xOffset = scrollView.contentOffset.x + bounds.size.width
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset.x = xOffset
        } completion: { _ in
            self.resetContentOffsetIfNeeded()
            self.isTurningPage = false
        }
    }

    /// Scrolls to the previous page.
    func scrollToPreviousPage() {
        guard !isTurningPage else { return }
        isTurningPage = true

        let xOffset = scrollView.contentOffset.x - bounds.size.width
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset.x = xOffset
        } completion: { _ in
            self.resetContentOffsetIfNeeded()
            self.isTurningPage = false
        }
    }
}

// MARK: - Private methods
private extension LoopedScrollView {

    func setup() {
        addSubviewAndStretchToFill(scrollView)
        scrollView.delegate = self

        scrollView.addSubviewAndStretchToFill(stackView)
        let stackWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: bounds.width)
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalTo: heightAnchor),
            stackWidthConstraint
        ])
        self.stackWidthConstraint = stackWidthConstraint
    }

    func addPage(_ view: UIView) {
        stackView.addArrangedSubview(view)
    }

    func resetContentOffsetIfNeeded() {
        currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)

        if currentPage == 0 {
            scrollView.contentOffset.x = bounds.size.width * CGFloat(numberOfItems)
        } else if currentPage == numberOfItems + 1 {
            scrollView.contentOffset.x = bounds.size.width
        }
    }
}

// MARK: - UIScrollViewDelegate
extension LoopedScrollView: UIScrollViewDelegate {

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resetContentOffsetIfNeeded()
    }
}
