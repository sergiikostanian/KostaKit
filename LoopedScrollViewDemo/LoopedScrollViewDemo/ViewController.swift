//
//  ViewController.swift
//  LoopedScrollViewDemo
//
//  Created by Serhii Kostanian on 21.03.2021.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var loopedScrollView: LoopedScrollView!

    var items: [UIColor] = [#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1), #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)]

    override func viewDidLoad() {
        super.viewDidLoad()
        loopedScrollView.dataSource = self
        loopedScrollView.reloadData()
    }

    @IBAction func leftButtonTapped(_ sender: Any) {
        loopedScrollView.scrollToPreviousPage()
    }

    @IBAction func rightButtonTapped(_ sender: Any) {
        loopedScrollView.scrollToNextPage()
    }
}

extension ViewController: LoopedScrollViewDataSource {

    func numberOfItems(in view: LoopedScrollView) -> Int {
        return items.count
    }

    func loopedScrollView(_ view: LoopedScrollView, itemAt index: Int) -> UIView {
        let pageView = PageView()
        pageView.titleLabel.text = "\(index + 1)"
        pageView.backgroundColor = items[index]
        return pageView
    }
}


class PageView: UIView {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 50, weight: .black)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        addSubviewAndStretchToFill(titleLabel)
    }
}
