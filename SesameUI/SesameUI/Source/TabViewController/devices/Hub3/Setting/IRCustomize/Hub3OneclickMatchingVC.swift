//
//  Hub3OneclickMaatchVC.swift
//  SesameUI
//
//  Created by eddy on 2024/2/19.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

class Hub3OneclickMatchingVC: CHBaseViewController {
    
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    lazy var hintView = {
        return StateHintView()
    }()
    private lazy var layout = {
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 1
        let screenWidth = UIScreen.main.bounds.width
        let minimumItemSpacing: CGFloat = 1
        let itemWidth = (screenWidth - padding * 2 - minimumItemSpacing * 2) / 3
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = minimumItemSpacing
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view =  UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.register(UINib(nibName: cellIdentify, bundle: nil), forCellWithReuseIdentifier: cellIdentify)
        view.bounces = false
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = .sesameBackgroundColor
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    private lazy var irReceiverImg: GIFImageView = {
        let lottie = GIFImageView(frame: .zero)
        lottie.contentMode = .scaleAspectFit
        return lottie
    }()
    
    private lazy var saveView = {
        let saveView = CHUICallToActionView() { [unowned self] sender,_ in
            ChangeValueDialog.showInView("", viewController: self, title: "一键匹配遥控器", hint: "co.candyhouse.hub3.rcInputHint".localized) { [weak self] newValue in
                guard let self = self else { return }
//                let vc = Hub3IRCustomizeControlVC.instance()
//                vc.navigationItem.title = newValue
//                navigationController?.pushViewController(vc, animated: true)
            }
        }
        saveView.title = "正常响应，保存为遥控器"
        return saveView
    }()
    
    private var readingMode: GuideState = .prepare {
        didSet {
            hintView.state = readingMode
            let isComplete = readingMode == .complete
            collectionView.isHidden = !isComplete
            irReceiverImg.isHidden = isComplete
            saveView.isHidden = !isComplete
        }
    }
    let dataSource = ["打开", "关闭", "模式"]
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView() {
//        view.backgroundColor = .sesame2Gray
        scrollView.addSubview(contentStackView)
        view.addSubview(scrollView)
        
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill
        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        
        contentStackView.addArrangedSubview(hintView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        contentStackView.addArrangedSubview(irReceiverImg)
        irReceiverImg.autoLayoutHeight(140)
        
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        contentStackView.addArrangedSubview(collectionView)
        collectionView.autoLayoutHeight(layout.itemSize.height)
        
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let startView = CHUICallToActionView() { [unowned self] sender,_ in
            self.readingMode = .reading
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.readingMode = .complete
            }
        }
        startView.title = "co.candyhouse.sesame2.Start".localized
        contentStackView.addArrangedSubview(startView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        contentStackView.addArrangedSubview(saveView)
        readingMode = .prepare
        
        irReceiverImg.prepareForAnimation(withGIFNamed: "learning") { [weak self] in
            self?.irReceiverImg.startAnimatingGIF()
        }
    }
}

extension Hub3OneclickMatchingVC: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { dataSource.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentify, for: indexPath) as! IRRemoteControlCell
        let model = dataSource[indexPath.row]
        cell.funcLabel.text = model
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let model = viewModel.dataSource[indexPath.row]
//        IRControlViewModel.sharedInstance.emitIRCode(id: model.rawValue.irCodeID) { _ in }
    }
}



enum GuideState {
    case prepare
    case reading
    case complete
    
    var desc: String {
        switch self {
        case .prepare:   return "请将手机靠近 Hub3，点击开始后，将手中遥控器对准设备并按下遥控器上的按键，系统会自动找到最匹配的遥控器"
        case .reading:   return "读取中..."
        case .complete:  return "请将手机对准 Hub3，并轻敲下方按钮，观看你的电器是否全部做出准确的响应"
        }
    }
}

class StateHintView: UIView {
    var state: GuideState = .prepare {
        didSet {
            hintLabel.text = state.desc
//            indicator.isHidden = state != .reading
        }
    }
    
    lazy var hintLabel: UILabel = {
        let label = UILabel.label(state.desc, UIColor.sesame2Gray)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(hintLabel)
        hintLabel.autoPinEdgesToSuperview(safeArea: false)

        addSubview(indicator)
        indicator.autoPinCenter()
        backgroundColor = .white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        autoPinTop()
        autoPinLeading()
        autoPinTrailing()
        autoLayoutHeight(216)
    }
}
