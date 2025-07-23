//
//  Hub3IRRemoteMatchControlVC.swift
//  SesameUI
//
//  Created by wuying on 2025/3/10.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

// MARK: - Hub3IRRemoteMatchControlCell Cell
class Hub3IRRemoteMatchControlCell: UICollectionViewCell {
    private lazy var containerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()
    
    lazy var funcLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    lazy var stateIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return imageView
    }()
    

    private let bottomBorder = CALayer()
    private let rightBorder = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupBorders()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addArrangedSubview(stateIcon)
        containerView.addArrangedSubview(funcLabel)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupBorders() {
        backgroundColor = .white
        bottomBorder.backgroundColor = UIColor.sesameRemoteBackgroundColor.cgColor
        layer.addSublayer(bottomBorder)
        rightBorder.backgroundColor = UIColor.sesameRemoteBackgroundColor.cgColor
        layer.addSublayer(rightBorder)
    }
    
    func configureBordersForPosition(indexPath: IndexPath, totalItems: Int, numberOfColumns: Int = 3) {
        let currentRow = indexPath.item / numberOfColumns
        let currentColumn = indexPath.item % numberOfColumns
        let totalRows = (totalItems + numberOfColumns - 1) / numberOfColumns
        let showRightBorder = (currentColumn != numberOfColumns - 1)
        let showBottomBorder = currentRow != totalRows - 1
        
        bottomBorder.isHidden = !showBottomBorder
        rightBorder.isHidden = !showRightBorder
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bottomBorder.frame = CGRect(
            x: 0,
            y: bounds.height - 2,
            width: bounds.width,
            height: 2
        )
        rightBorder.frame = CGRect(
            x: bounds.width - 2,
            y: 0,
            width: 2,
            height: bounds.height
        )
    }
    
    func updateLayout(showIcon: Bool) {
        stateIcon.isHidden = !showIcon
        if showIcon {
            funcLabel.textAlignment = .left
        } else {
            funcLabel.textAlignment = .center
        }
        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        funcLabel.text = nil
        funcLabel.attributedText = nil
        funcLabel.textColor = .black
        stateIcon.image = nil
        updateLayout(showIcon: false)
    }
}


// MARK: - Main View Controller
class Hub3IRRemoteMatchControlVC: CHBaseViewController, ShareAlertConfigurator {
    
    // MARK: - Properties
    private var currentGroup:Int = 1  // Start from 1 for user-friendly display
    private var currentButton:Int = 1  // Start from 1 for user-friendly display
    private var totalGroups:Int = 5
    private var totalButtons:Int = 7
    private let BOTTOM_BUTTON_HEIGHT = 44.0
    private var cooldownIndex: Int? = nil
    private var currentHighlightIndex:Int = 0  // Track the currently highlighted cell
    private var buttonContainerViewBottomConstraint: NSLayoutConstraint!
    private var buttonContainerViewHeight: NSLayoutConstraint!
    public private(set) var viewModel: Hub3IRRemoteMatchViewModel!
    private var tag:String = "Hub3IRRemoteMatchControlVC"
    typealias MatchCompletionHandler = (Bool, [String: Any]?) -> Void
    var matchCompletionHandler: MatchCompletionHandler?

    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "co.candyhouse.hub3.air_match_introduction".localized
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.textColor = .darkGray
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.text = ""
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 0
        let screenWidth = UIScreen.main.bounds.width
        let minimumItemSpacing: CGFloat = 0
        let itemWidth = (screenWidth - padding * 2 - minimumItemSpacing * 2) / 3
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = minimumItemSpacing
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        let view = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.backgroundColor = .white
        view.bounces = false
        view.showsVerticalScrollIndicator = false
        view.delegate = self
        view.dataSource = self
        view.register(Hub3IRRemoteMatchControlCell.self, forCellWithReuseIdentifier: "Cell")
        return view
    }()
    
    private lazy var footerLabel: UILabel = {
        let label = UILabel()
        label.text = "co.candyhouse.hub3.ir_support_info".localized
        label.textColor = UIColor.placeHolderColor
        label.font = UIFont(name: "TrebuchetMS", size: 15)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.backgroundColor = UIColor(hexString: "#ffffff")
        return stack
    }()
    
    
    private lazy var noResponseButton: UIButton = {
        let button = UIButton()
        button.setTitle("co.candyhouse.hub3.air_match_no_respond_turn_next".localized, for: .normal)
        button.backgroundColor = UIColor(hexString: "#cccccc")
        button.layer.cornerRadius = 8
        button.titleLabel?.numberOfLines = 0 // 允许多行
        button.titleLabel?.lineBreakMode = .byWordWrapping // 按单词换行
        button.titleLabel?.textAlignment = .center // 文字居中
        button.addTarget(self, action: #selector(noResponseTapped), for: .touchUpInside)
        return button
        
    }()
    
    
    private lazy var hasResponseButton: UIButton = {
        let button = UIButton()
        button.setTitle("co.candyhouse.hub3.air_match_responded".localized, for: .normal)
        button.backgroundColor = UIColor(hexString: "#28aeb1")
        button.layer.cornerRadius = 8
        button.titleLabel?.numberOfLines = 0 // 允许多行
        button.titleLabel?.lineBreakMode = .byWordWrapping // 按单词换行
        button.titleLabel?.textAlignment = .center // 文字居中
        button.addTarget(self, action: #selector(hasResponseTapped), for: .touchUpInside)
        return button
    }()
    
    init(viewModel: Hub3IRRemoteMatchViewModel!) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        updateHintText()
        configData()
        setupObservers()
        updateFooterText()
    }
    
    private func setupObservers() {
        viewModel.observeIRMatchItemList { [weak self] items in
            self?.totalButtons = self?.viewModel.irMatchItemList.count ?? 7
            self?.updateHintText()
            self?.collectionView.reloadData()
        }
    }
    
    private func configData() {
        viewModel.getCompanyCodeByModel() { companyCode in
            if let company = companyCode {
                self.totalGroups = company.code.count - 1
                self.updateHintText()
                self.updateResponseButtonText()
                self.updateNoResponseButtonText()
                L.d(self.tag,"configData self.totalGroups=\(self.totalGroups)")
            } else {
                L.d(self.tag,"can not find codes !")
            }
        }
        
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(titleLabel)
        view.addSubview(hintLabel)
        view.addSubview(collectionView)
        
        view.addSubview(footerLabel)
        view.addSubview(buttonContainerView)
        buttonContainerView.addSubview(buttonStackView)
        
        buttonStackView.addArrangedSubview(hasResponseButton)
        buttonStackView.addArrangedSubview(noResponseButton)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        let containerHeight = BOTTOM_BUTTON_HEIGHT + 80
        buttonContainerViewHeight = buttonContainerView.heightAnchor.constraint(equalToConstant: containerHeight)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            hintLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            hintLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            hintLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: footerLabel.topAnchor, constant: -8),
            
            footerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -1),
            footerLabel.heightAnchor.constraint(equalToConstant: 20),
            
            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerViewHeight,
            buttonStackView.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -16),
            buttonStackView.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 16),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -56), // 底部留空
        ])
        buttonContainerViewBottomConstraint = buttonContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        buttonContainerViewBottomConstraint.isActive = true
        
    }
    
    private func updateHintText() {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            self.hintLabel.text = String(format:
                                            NSLocalizedString("co.candyhouse.hub3.ir_match_key", comment: ""),
                                         self.currentButton,
                                         self.currentGroup,
                                         self.totalGroups,
                                         self.totalButtons
            )
            
        }
    }
    
    private func showButtonStackView() {
        buttonContainerView.isHidden = false
        buttonStackView.isHidden = false
        buttonStackView.alpha = 1
        view.layoutIfNeeded()
        buttonContainerView.transform = CGAffineTransform(translationX: 0, y: buttonContainerViewHeight.constant)
        UIView.animate(withDuration: 0.3) {
            self.buttonContainerView.transform = .identity
            self.view.layoutIfNeeded()
        }
    }
    private func hideButtonStackView(completion: (() -> Void)? = nil) {
        // 动画隐藏
        UIView.animate(withDuration: 0.3, animations: {
            self.buttonContainerView.transform = CGAffineTransform(translationX: 0, y: self.buttonContainerViewHeight.constant)
            self.view.layoutIfNeeded()
        }) { _ in
            self.buttonContainerView.isHidden = true
            self.buttonContainerView.transform = .identity
            completion?()
        }
    }
    
    private func updateNoResponseButtonText() {
        if currentGroup >= totalGroups {
            noResponseButton.setTitle("co.candyhouse.hub3.air_match_no_respond".localized, for: .normal)
        } else {
            noResponseButton.setTitle("co.candyhouse.hub3.air_match_no_respond_turn_next".localized, for: .normal)
        }
    }
    
    private func updateResponseButtonText() {
        if currentButton >= totalButtons {
            hasResponseButton.setTitle("co.candyhouse.hub3.air_match_finished".localized, for: .normal)
        } else {
            hasResponseButton.setTitle("co.candyhouse.hub3.air_match_responded".localized, for: .normal)
        }
    }
    
    private func moveToNextButton() {
        currentButton += 1
        if currentButton > totalButtons {
            currentButton = totalButtons
        }
        currentHighlightIndex = currentButton - 1
        updateHintText()
        updateResponseButtonText()
        updateNoResponseButtonText()
        collectionView.reloadData()
    }
    
    private func moveToNextGroup() {
        currentGroup += 1
        currentButton = 1
        if currentGroup > totalGroups {
            currentGroup = totalGroups
        }
        currentHighlightIndex = 0
        updateHintText()
        updateNoResponseButtonText()
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func noResponseTapped() {
        noResponseButton.backgroundColor = UIColor(hexString: "#bbbbbb")
        hideButtonStackView {
            if self.currentGroup < self.totalGroups {
                self.moveToNextGroup()
            }
            self.noResponseButton.backgroundColor = UIColor(hexString: "#cccccc")
        }
    }
    
    @objc private func hasResponseTapped() {
        hasResponseButton.backgroundColor = UIColor(hexString: "#189799")
        hideButtonStackView {
            self.moveToNextButton()
            self.hasResponseButton.backgroundColor = UIColor(hexString: "#28aeb1")
        }
        if currentButton >= totalButtons {
            showSaveDialog()
        }
    }
    
    @objc private func showSaveDialog() {
        let name: String = viewModel.getCurrentRemoteDevice().alias
        ChangeValueDialog.showInView(name, viewController: self, title: "co.candyhouse.hub3.rcInputHint".localized, hint: "co.candyhouse.hub3.irRenameHint".localized) { [weak self] newValue in
            guard let self = self else { return }
            if (newValue as NSString).length > REMOTE_MAX_NAME_LENGTH {
                self.view.makeToast("Length exceeds limit")
                return
            }
            viewModel.postIrRemoteDevice(name: newValue) { success in
                executeOnMainThread {
                    if success {
                        L.d(self.tag, "add device success !")
                        self.matchCompletionHandler?(true, nil)
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.view.makeToast("co.candyhouse.hub3.air_match_add_failed".localized)
                        self.showButtonStackView()
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension Hub3IRRemoteMatchControlVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.irMatchItemList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Hub3IRRemoteMatchControlCell
        let item = viewModel.irMatchItemList[indexPath.item]
        cell.funcLabel.text = item.title
        if indexPath.item == currentHighlightIndex {
            cell.contentView.backgroundColor = UIColor.sesame2Green
            cell.funcLabel.textColor = .white
        } else {
            cell.contentView.backgroundColor = .white
            cell.funcLabel.textColor = (cooldownIndex == indexPath.row) ? .gray : .black
        }
        if indexPath.item < currentHighlightIndex {
            cell.stateIcon.image = UIImage(named: "icon_match_success")
            cell.stateIcon.isHidden = false
        } else {
            cell.stateIcon.isHidden = true
        }
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section)
        cell.configureBordersForPosition(indexPath: indexPath, totalItems: totalItems)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == currentHighlightIndex {
            viewModel.handleItemClick(position: indexPath.row)
            showButtonStackView()
        } else {
            self.view.makeToast("co.candyhouse.hub3.air_match_item_tips".localized)
        }
    }
    
    private func updateFooterText() {
        if let model = viewModel.getInitIrRemoteDevice()?.model, !model.isEmpty {
            footerLabel.text = "\("co.candyhouse.hub3.ir_support_info".localized) \(model)"
        } else {
            footerLabel.text = "co.candyhouse.hub3.ir_support_info".localized
        }
    }
}


extension Hub3IRRemoteMatchControlVC {
    static func instance(device: CHHub3,
                         irReomte: IRRemote,
                         completion: @escaping (Bool, [String: Any]?) -> Void = { _, _ in }
    ) -> Hub3IRRemoteMatchControlVC {
        let vc =  Hub3IRRemoteMatchControlVC(viewModel: Hub3IRRemoteMatchViewModel(device: device,irRemote: irReomte))
        vc.matchCompletionHandler = completion
        return vc
    }
}
