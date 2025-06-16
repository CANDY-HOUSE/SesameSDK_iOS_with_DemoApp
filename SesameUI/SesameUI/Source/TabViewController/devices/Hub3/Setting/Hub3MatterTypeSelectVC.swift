//
//  Hub3MatterSelectVC.swift
//  SesameUI
//
//  Created by eddy on 2024/1/5.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

struct MatterTypeItem {
    var icon: String
    var name: String
    var type: MatterProductModel
    var isOn: Bool = false
    
    func convertToCellDescriptorModel(cellCls: AnyClass, changeListenerHandler: ((MatterTypeItem, _ cell: UITableViewCell) -> Void)?) -> CHCellDescriptor {
        return CHCellDescriptor(cellCls: cellCls, rawValue: self) { cell in
            cell.configure(item: self)
            (cell as? MatterTypeViewCell)?.onActionChange = { action in
                changeListenerHandler!(action, cell as! UITableViewCell)
            }
        }
    }
}


class Hub3MatterTypeSelectVC: CHBaseViewController {
    
    private var deviceTuple: (CHHub3, CHDevice)!
    private var dataSource = [MatterTypeItem]() {
        didSet {
            let discriptors = dataSource.map { it -> CHCellDescriptor in
                return it.convertToCellDescriptorModel(cellCls: MatterTypeViewCell.self) { [weak self] model, cell in
                    guard let self = self else { return }
                    let idxPath = self.tableViewProxy.tableView.indexPath(for: cell)
                    guard let path = idxPath else { return }
                    self.dataSource[path.row] = model
                }
            }
            self.tableViewProxy.handleSuccessfulDataSource(nil, discriptors)
        }
    }
    var tableViewProxy: CHTableViewProxy!
    
    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = .white
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
                //移除置頂是白色。畫面向下滑動變黑的特性
        } else {
            navigationController?.navigationBar.barTintColor = .white
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureTable()
        prepareData()
    }
    
    func configureTable() {
        tableViewProxy = CHTableViewProxy(superView: self.view, selectHandler: { it ,_ in
            
        } ,emptyPlaceholder: nil)
        tableViewProxy.configureTableHeader(nil, nil)
        tableViewProxy.tableView.backgroundColor = UIColor.sesameBackgroundColor
        tableViewProxy.tableView.bounces = false
        configureHeader()
        configureFooter()
    }
    
    func configureHeader() {
        tableViewProxy.tableView.tableHeaderView = {
            let backView = UIView(frame: .init(origin: .init(x: 0, y: 0), size: .init(width: CGRectGetWidth(tableViewProxy.tableView.frame), height: 160)))
            backView.backgroundColor = .sesameBackgroundColor
            let view = UIView(frame: backView.bounds)
            backView.addSubview(view)
            view.autoLayoutHeight(144)
            view.autoPinWidth()
            view.backgroundColor = .white
            
            let iconImgView = UIImageView(image: UIImage.SVGImage(named: "matter_sym_rgb_night"))
            view.addSubview(iconImgView)
            iconImgView.autoLayoutWidth(55)
            iconImgView.autoLayoutHeight(55)
            iconImgView.autoPinCenterY(constant: -20)
            iconImgView.autoPinCenterX()
            
            let label = UILabel(frame: .zero)
            label.text = String(format: "co.candyhouse.hub3.matterTip".localized, arguments: [deviceTuple.1.deviceName])
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            view.addSubview(label)
            label.autoPinTopToBottomOfView(iconImgView, constant: 16)
            label.autoPinLeading(constant: 32)
            label.autoPinTrailing(constant: -32)
            return backView
        }()
    }
    
    func configureFooter() {
        tableViewProxy.tableView.tableFooterView = {
            let backView = UIView(frame: .init(origin: .init(x: 0, y: 0), size: .init(width: CGRectGetWidth(tableViewProxy.tableView.frame), height: 66)))
            backView.backgroundColor = .sesameBackgroundColor
            let matterBack = UIView(frame: .zero)
            matterBack.backgroundColor = .white
            backView.addSubview(matterBack)
            matterBack.autoPinLeading()
            matterBack.autoPinRight()
            matterBack.autoPinBottom()
            matterBack.autoPinTop(constant: 16)
            let addMatter = CHUICallToActionView() { [unowned self] sender,_ in
                var matterType: MatterProductModel = .none
                for item in self.dataSource {
                    if !item.isOn { continue }
                    matterType = item.type
                }
                let (baseDevice, insertDevice) = self.deviceTuple
                ViewHelper.showLoadingInView(view: self.view)
                baseDevice.insertSesame(insertDevice, nickName: baseDevice.deviceName, matterProductModel: matterType) { [weak self] result in
                    guard let self = self else { return }
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        if case let .failure(err) = result {
                            self.view.makeToast(err.errorDescription())
                        } else {
                            // 回到设置页
                            if let viewControllers = self.navigationController?.viewControllers {
                                for viewController in viewControllers.reversed() {
                                    if let settingVC = viewController as? Hub3SettingViewController {
                                        self.navigationController?.popToViewController(settingVC, animated: true)
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
            addMatter.title = "co.candyhouse.hub3.matterAdd".localized
            matterBack.addSubview(addMatter)
            addMatter.autoPinEdgesToSuperview()
            return backView
        }()
    }
    
    func prepareData() {
        let (_, insertDevice) = self.deviceTuple
//        let deviceTypesMapping = IRDeviceType.deviceTypes
        var irItems = [MatterTypeItem]()
        let matterRoleMapping = [
            MatterProductModel.doorLock: MatterTypeItem(icon: "lock", name: "co.candyhouse.hub3.matterLock".localized, type: .doorLock, isOn: true),
            MatterProductModel.onOffSwitch: MatterTypeItem(icon: "switch", name: "co.candyhouse.hub3.matterSwitch".localized, type: .onOffSwitch, isOn: true)
        ]
        if let mappedValue = matterRoleMapping[insertDevice.productModel.defaultMatterRole] {
            irItems.append(mappedValue)
        }
        self.dataSource = irItems
        //        XMLParseHandler.fetchXMLContent(fileName: deviceTypesMapping.fileName, eleAttrName: deviceTypesMapping.attName) { [weak self] contens in
        //            guard let self = self else { return }
        //            var irItems = contens.enumerated().map { (index,ele) in
        //                let type = IRDeviceType.allCases[index]
        //                let shouldOpen = insertDevice.productModel.defaultMatterRole == .doorLock
        //                return MatterTypeItem(icon: type.modelsMapping.icon, name: ele, type: type, isOn: false)
        //            }
//        }
    }
}

extension Hub3MatterTypeSelectVC {
    static func instance(_ tuple: (CHHub3, CHDevice)) -> Hub3MatterTypeSelectVC {
        let vc =  Hub3MatterTypeSelectVC()
        vc.deviceTuple = tuple
        return vc
    }
}
