//
//  Hub3IRControlSettingVC.swift
//  SesameUI
//
//  Created by eddy on 2023/12/29.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import UIKit

class Hub3IRCustomizeControlVC: CHBaseViewController, ShareAlertConfigurator {
    
    public private(set) var viewModel: IRLearningViewModel!
    private weak var emptyFloatView: FloatingTipView?
    
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
        let view =  UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.bounces = false
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = .white
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    private lazy var isPresentedVc: Bool = {
        return presentingViewController != nil
    }()
    
    init(viewModel: IRLearningViewModel!) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        viewModel.gaurdRegisterMode()
        L.d("Hub3IRCustomizeControlVC deinit")
    }
    
    @objc func modifyName(){
        if isPresentedVc { return }
        ChangeValueDialog.showInView(viewModel.payload.alias,
                                     viewController: self,
                                     title: "co.candyhouse.hub3.rcInputHint".localized,
                                     hint: "co.candyhouse.hub3.irRenameHint".localized) { [weak self] newValue in
            if (newValue as NSString).length > REMOTE_MAX_NAME_LENGTH {
                self?.view.makeToast("Length exceeds limit")
                return
            }
            self?.postDeviceAlias(newValue)
        }
    }
    

    private func updateIRRemoteAlias(_ alias: String) {
        viewModel.updateIRRemoteAlias(alias)
        configureNavTitle()
    }
    
    private func postDeviceAlias(_ alias: String) {
        showOverLayLoadingView(view: navigationItem.titleView,backgroudeColor: UIColor(hexString: "#F2F2F7"))
        viewModel.device.updateIRDevice([
            "uuid": viewModel.payload.uuid,
            "alias": alias
        ]) { [weak self] res in
            self?.hideOverLayLoadingView()
            if case .success(_) = res {
                executeOnMainThread {
                    self?.updateIRRemoteAlias(alias)
                }
            }
        }
    }
    
    func configureNavItem() {
        if isPresentedVc { return }
        setNavigationRightItem(viewModel.isRegisterMode ? "icons_filled_close" : "icons_outlined_addoutline", #selector(onIRModeButtonTapped(_:)))
    }
    
    func configureNavTitle() {
        setNavigationBarSubtitle(title: viewModel.getRemoteName(), subtitle: nil) { [weak self] in
            self?.modifyName()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavItem()
        configureNavTitle()
        configureTable()
        configureViewModel()
    }
    
    func configureEmptyView() {
        guard emptyFloatView == nil else { return }
        let emptyHit = isPresentedVc
            ? "co.candyhouse.hub3.ir_empty_controll".localized
            : "co.candyhouse.hub3.ir_empty_learning".localized
        let floatView = FloatingTipView.showIn(superView: view, style:  .textOnly(text:emptyHit))
        floatView.backgroundColor = .white
        executeOnMainThread { [weak self] in
            self?.collectionView.contentInset = .init(top: floatView.FloatingHeight, left: 0, bottom: 0, right: 0)
            self?.emptyFloatView = floatView
        }
    }
    
    func removeEmptyView() {
        guard let floatView = emptyFloatView else { return }
        executeOnMainThread { [weak self] in
            self?.collectionView.contentInset = .zero
        }
        floatView.removeFromSuperview()
        emptyFloatView = nil
    }
    
    func configureTable() {
        title = navigationItem.title
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperview(safeArea: false)
        collectionView.register(UINib(nibName: cellIdentify, bundle: nil), forCellWithReuseIdentifier: cellIdentify)
    }
    
    func configureViewModel() {
        viewModel.didUpdate = { [weak self] vm in
            self?.collectionView.reloadData()
            if(self?.viewModel.dataSource.count == 0){
                self?.configureEmptyView()
            } else {
                self?.removeEmptyView()
            }
        }
        viewModel.onError = { [weak self] err in
            // 当蓝牙打开未连接时，需要切换为专门提醒：提醒用户返回详情界面连接设备;国际化弹窗提示语
            if((err as NSError).code == NSError.deviceNotLoggedIn.code && (err as NSError).description == NSError.deviceNotLoggedIn.description){
                self?.view.makeToast("co.candyhouse.sesame2.ir_ble_invalid".localized)
                return
            } else if ((err as NSError).code == NSError.blePoweredOff.code && (err as NSError).description == NSError.blePoweredOff.description){
                self?.view.makeToast("co.candyhouse.sesame2.ir_ble_noable".localized)
                return
            }
            self?.view.makeToast(err.errorDescription())
        }
        viewModel.onModeChange = { [weak self] _ in
            self?.configureNavItem()
        }
        viewModel.onIRKeysStatusChange = {[weak self] isSuccess in
            self?.hideLoadingView()
            if(!isSuccess) {
                self?.showErrorView()
            }
        }
        viewModel.didChange = {[weak self]  in
            self?.hideOverLayLoadingView()
        }
        showLoadingView()
        viewModel.viewDidLoad()
    }
    
    @objc func onIRModeButtonTapped(_ sender: UIBarButtonItem) {
        switchMode()
    }
    
    func switchMode() {
        viewModel.switchIRMode { [weak self] yesOrNo in
            guard let self = self else { return }
            if viewModel.isRegisterMode {
                self.viewModel.subscribeServerForPostIRDataWhenModelSwitch()
            } else {
                self.viewModel.unsubscribeServerForPostIRData()
            }
            self.configureNavItem()
        }
    }
    
    func handleSelectRow(_ ir: IRItem,cell: IRRemoteControlCell) {
        modalSheet(AlertModel(message: nil, sourceView: cell, items: [
            AlertItem(title: "co.candyhouse.hub3.default_ir_name".localized) { _ in
                ChangeValueDialog.show(ir.title, title: "co.candyhouse.hub3.default_ir_name".localized, hint: "co.candyhouse.hub3.irRenameHint".localized) { [unowned self] name in
                    if name == ir.title { return }
                    self.showOverLayLoadingView(view:cell,backgroudeColor: .white)
                    self.viewModel.changeIRCode(id: ir.rawValue.keyUUID, name: name) { _ in }
                }
            },
            AlertItem(title: "co.candyhouse.sesame2.Delete".localized, style: .destructive) { [unowned self] _ in
                self.showOverLayLoadingView(view: cell,backgroudeColor: .white)
                self.viewModel.deleteIR(id: ir.rawValue.keyUUID) { _ in }
            },
            AlertItem(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: { _ in })
        ]))
    }
    
    private func showLoadingView() {
        ViewHelper.showLoadingInView(view: view, backgroudeColor:.white)
    }
    
    private func hideLoadingView() {
        ViewHelper.hideLoadingView(view: view)
    }
    
    private func showErrorView() {
        ViewHelper.showErrorView(
            view: view,
            image: UIImage.SVGImage(named: "icon_network_error"),
            message: "co.candyhouse.hub3.ir_retry_network_tips".localized,
            onClick: {
                self.retryLoading()
            })
    }
    
    private func hideErrorView() {
        ViewHelper.hideErrorView(view: view)
    }
    
    private func showOverLayLoadingView(view: UIView?,backgroudeColor: UIColor) {
        executeOnMainThread {
            ViewHelper.showLoadingInView(view: view, backgroudeColor: backgroudeColor,floating:false)
        }
    }
    
    private func hideOverLayLoadingView() {
        executeOnMainThread{
            ViewHelper.hideLoadingView(view:self.view)
        }
    }
    
    private func retryLoading() {
        hideErrorView()
        showLoadingView()
        viewModel.viewDidLoad() // 重新加载数据
    }
}

extension Hub3IRCustomizeControlVC: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { viewModel.dataSource.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentify, for: indexPath) as! IRRemoteControlCell
        let model = viewModel.dataSource[indexPath.row]
        cell.funcLabel.text = model.title.isEmpty ? defaultPlaceHolder() : model.title
        cell.longPressHandler = !isPresentedVc ? { [unowned self] in
            self.handleSelectRow(model,cell:cell)
        } : nil
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section)
        cell.configureBordersForPosition(indexPath: indexPath, totalItems: totalItems)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = viewModel.dataSource[indexPath.row]
        self.viewModel.subscribeServerForPostIRDataWhenEmitCode(model.rawValue.keyUUID)
        viewModel.emitIRCode(id: model.rawValue.keyUUID) { [self] isSucc in
            if isSucc {
                self.view.makeToast("co.candyhouse.sesame2.ir_send_success".localized)
            }
        }
    }
    
    private func defaultPlaceHolder() -> String {
        var placeHolder = "co.candyhouse.hub3.ir_key_emit".localized
        if !isPresentedVc {
            placeHolder = "co.candyhouse.hub3.ir_key_edit".localized + "\n" + placeHolder
        }
        return placeHolder
    }
}

extension Hub3IRCustomizeControlVC {
    static func instance(device: CHHub3) -> Hub3IRCustomizeControlVC {
        let vc =  Hub3IRCustomizeControlVC(viewModel: IRLearningViewModel(device: device))
        return vc
    }
}
