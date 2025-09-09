//
//  RemoteControlVC.swift
//  SesameUI
//
//  Created by eddy on 2024/1/27.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

let cellIdentify = String(describing: IRRemoteControlCell.self)
let REMOTE_MAX_NAME_LENGTH = 20
private let BOTTOM_BUTTON_HEIGHT = 80.0
class RemoteControlVC: CHBaseViewController {
    private let viewModel: RemoteControlViewModel
    private var cooldownIndex: Int? = nil  // 记录正在冷却的 cell 索引
    private var saveButton: UIBarButtonItem!
    private var currentItems: [IrControlItem] = []
    var cachedIrMatchList: [MatchIRRemote]? = nil
    
    private lazy var isPresentedVc: Bool = {
        return presentingViewController != nil
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 0
        let screenWidth = UIScreen.main.bounds.width
        let minimumItemSpacing: CGFloat = 0
        let itemWidth = (screenWidth - padding * 2 - minimumItemSpacing * 2) / 3
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth-10)
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = minimumItemSpacing
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        let view =  UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.bounces = false
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = .white
        view.delegate = self
        view.dataSource = self
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
    
    lazy var quickMatchView = {
        let containerView = UIView()
        containerView.backgroundColor = .white
        
        let label = UILabel()
        label.text = "co.candyhouse.hub3.air_control_match".localized
        label.textColor = .black
        label.textAlignment = .left
        label.numberOfLines = 0
        let iconImageView = UIImageView(image: UIImage(named: "arrow_right_black"))
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .black
        let stackView = UIStackView(arrangedSubviews: [label, iconImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            label.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, constant: -66)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(quickMatchTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        return containerView
    }()
    
    init(irRemote: IRRemote, hub3DeviceId: String) {
        self.viewModel = RemoteControlViewModel(remoteRepository: RemoteRepository())
        super.init(nibName: nil, bundle: nil)
        self.viewModel.setHub3DeviceId(hub3DeviceId)
        self.viewModel.setRemoteDevice(irRemote)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureTalbe()
        configureMatchView()
        configureFootLable()
        setupViewModelObservers()
        viewModel.initConfig(type: viewModel.irRemote!.type)
        self.viewModel.setupIrRemoteDeivceInfo()
        if(!viewModel.irRemote!.haveSave) {
            viewModel.setDeviceAlias(viewModel.irRemote!.alias+"🖋️")
        } else {
            viewModel.setDeviceAlias(viewModel.irRemote!.alias)
        }
        configureTitle()
        updateFooterText(viewModel.irRemote!.alias)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isPresentedVc { return }
        NotificationCenter.default.post( name: .remoteUpdated, object: nil, userInfo: ["irRemote": viewModel.irRemote])
    }
    
    private func setupViewModelObservers() {
            viewModel.uiStateDidChange = { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .loading:
                    // 显示加载状态
                    // self.showLoading()
                    break
                    
                case .success(let items, let layoutSettings, _):
                    self.currentItems = items
                    executeOnMainThread {
                        self.collectionView.reloadData()
                        self.configureTitle()
                        self.configureTitleRightButton()
                    }
                    
                case .error(let error):
                    executeOnMainThread {
                        self.view.makeToast(error.localizedDescription)
                    }
                }
            }
        }
    
    func configureTitle() {
        setNavigationBarSubtitle(title: viewModel.getDeviceAlias(), subtitle: viewModel.irRemote!.model) { [weak self] in
            self?.modifyName()
        }
    }
    private func configureTitleRightButton() {
        guard viewModel.getIrRemoteDevice()?.haveSave == false else {
            return
        }
        saveButton = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_remote_save"), style: .plain, target: self, action: #selector(saveButtonTapped))
        navigationItem.rightBarButtonItem = saveButton
    }
    
    
    @objc private func saveButtonTapped() {
        ChangeValueDialog.showInView(viewModel.getDeviceAlias(),
                                     viewController: self,
                                     title: "co.candyhouse.hub3.saveIRDeviceTitle".localized,
                                     hint: "co.candyhouse.hub3.irRenameHint".localized) { [weak self] newValue in
            if (newValue as NSString).length > REMOTE_MAX_NAME_LENGTH {
                self?.view.makeToast("Length exceeds limit")
                return
            }
            self?.viewModel.irRemote?.updateAlias(newValue)
            self?.postIRDevice{ _ in }
            self?.viewModel.setDeviceAlias(newValue)
            self?.configureTitle()
        }
    }
    
    
    @objc func modifyName(){
        if isPresentedVc { return }
        ChangeValueDialog.showInView(viewModel.getDeviceAlias(),
                                     viewController: self,
                                     title: "co.candyhouse.hub3.rcInputHint".localized,
                                     hint: "co.candyhouse.hub3.irRenameHint".localized) { [weak self] newValue in
            if (newValue as NSString).length > REMOTE_MAX_NAME_LENGTH {
                self?.view.makeToast("Length exceeds limit")
                return
            }
            if (self?.viewModel.irRemote?.haveSave == true) {
                self?.postDeviceAlias(newValue)
            } else {
                self?.viewModel.setDeviceAlias(newValue)
                self?.configureTitle()
            }
        }
    }
    
    func configureTalbe() {
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperview(safeArea: false)
        collectionView.register(UINib(nibName: cellIdentify, bundle: nil), forCellWithReuseIdentifier: cellIdentify)
    }
    
    /// 配置 匹配界面入口
    func configureMatchView() {
        if (viewModel.irRemote?.haveSave == true) {
            return
        }
        view.addSubview(quickMatchView)
        quickMatchView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quickMatchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            quickMatchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            quickMatchView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            quickMatchView.heightAnchor.constraint(equalToConstant: BOTTOM_BUTTON_HEIGHT)
        ])
    }
    
    func configureFootLable() {
        view.addSubview(footerLabel)
        NSLayoutConstraint.activate([
            footerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            footerLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func updateFooterText(_ text: String = "") {
        self.footerLabel.text = "\("co.candyhouse.hub3.ir_support_info".localized) \(text)"
    }
    
    @objc func quickMatchTapped() {
        
        let matchVC = Hub3IRRemoteMatchControlVC.instance(
            hub3DeviceId: viewModel.getHub3DeviceId(),
            irReomte: viewModel.irRemote!,
            existingMatchList: cachedIrMatchList){[weak self] successful, irRemote, irMatchList in
            guard let self = self else { return }
            if successful {
                updateReomteDeviceInfo()
                hideAddIrDeviceEntrance()
                self.cachedIrMatchList = irMatchList
            }
        }
        self.navigationController?.pushViewController(matchVC, animated: true)
    }
    /// 在自动匹配界面添加红外设备，需要更新页面数据
    private func updateReomteDeviceInfo(_ irRemote: IRRemote? = nil) {
        guard let irRemote = irRemote else { return }
        viewModel.setDeviceAlias(irRemote.alias)
        viewModel.setRemoteDevice(irRemote)
        configureTitle()
        updateFooterText(irRemote.model)
    }
    
    private func showQuickMatchView() {
        UIView.animate(withDuration: 0.3) {
            self.quickMatchView.isHidden = false
            self.quickMatchView.alpha = 1.0
        }
    }
    
    private func hideQuickMatchView() {
        UIView.animate(withDuration: 0.3) {
            self.quickMatchView.alpha = 0.0
        } completion: { _ in
            self.quickMatchView.isHidden = true
        }
    }
    
    private func postIRDevice(_ completion: @escaping (Bool) -> Void) {
        L.d("Hub3IRRemoteControlVC", "postIRDevice : \(viewModel.irRemote!.uuid)  \(viewModel.irRemote!.alias)")
        
        viewModel.addIRDeviceInfo(){[weak self] result in
            guard let self = self else { return }
            if (!result) {
                completion(false)
                return
            }
            executeOnMainThread {
                self.hideAddIrDeviceEntrance()
            }
            completion(true)
        }
    }
    
    private func hideAddIrDeviceEntrance() {
        navigationItem.rightBarButtonItem = nil
        hideQuickMatchView()
    }
    
    private func postDeviceAlias(_ alias: String) {
        if alias == viewModel.irRemote!.alias { return }
        viewModel.modifyRemoteIrDeviceInfo(alias: alias){[weak self] result in
            guard let self = self else { return }
            if(result) {
                viewModel.irRemote!.updateAlias(alias)
                viewModel.setDeviceAlias(alias)
                configureTitle()
            }
        }
    }
}

extension RemoteControlVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { currentItems.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentify, for: indexPath) as! IRRemoteControlCell
//        let keyModel = dataGenerator.funcKeys[indexPath.item]
        let item = currentItems[indexPath.item]
        cell.funcLabel.attributedText = NSAttributedString(string: item.title)
        cell.funcLabel.textColor = (cooldownIndex == indexPath.row) ? .sesame2LightGray : .black
        cell.stateIcon.isHidden = item.iconRes == ""
        cell.stateIcon.image = cell.stateIcon.isHidden ? nil : UIImage(named: item.iconRes)
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section)
        cell.configureBordersForPosition(indexPath: indexPath, totalItems: totalItems)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 使用冷却管理方法
        guard handleCellCooldown(at: indexPath) else {
            return  // 如果在冷却中，直接返回
        }
        viewModel.handleItemClick(item:  currentItems[indexPath.item])
    }
    private func handleCellCooldown(at indexPath: IndexPath, cooldownDuration: TimeInterval = 1.0) -> Bool {
        // 如果正在冷却中，返回 false
        if cooldownIndex == indexPath.row {
            return false
        }
        // 记录冷却状态
        cooldownIndex = indexPath.row
        // 延迟恢复
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownDuration) { [weak self] in
            // 清除冷却状态
            self?.cooldownIndex = nil
            // 刷新恢复正常颜色
            self?.collectionView.reloadData()
        }
        return true
    }
}

extension RemoteControlVC {
    static func instance(irRemote: IRRemote, hub3DeviceId: String) -> RemoteControlVC {
        return RemoteControlVC(irRemote: irRemote, hub3DeviceId: hub3DeviceId)
    }
}
