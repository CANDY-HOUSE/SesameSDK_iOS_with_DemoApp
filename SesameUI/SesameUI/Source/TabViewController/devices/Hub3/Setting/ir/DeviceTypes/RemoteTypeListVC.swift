//
//  Hub3IRDeviceTypeVC.swift
//  SesameUI
//
//  Created by eddy on 2024/1/25.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK


typealias deviceType = Int
struct DeviceTypeItem {
    var type: deviceType
    var name: String
    var iconStr: String
    let raw: ContentModel
}

class RemoteTypeListVC : CHBaseViewController {
    
    lazy var tableView: UITableView = {
        let table = UITableView.ch_tableView(view, .plain, "", nil, false)
        table.rowHeight = 55
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    var hub3DeviceId: String = ""
    
    private var dataSource = [DeviceTypeItem]() {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTable()
        fetchData()
    }

    func configureTable() {
        view.addSubview(self.tableView)
        view.backgroundColor = .white
    }
    
    func fetchData() {
        let deviceTypesMapping = IRType.deviceTypes
        XMLParseHandler.fetchXMLContent(fileName: deviceTypesMapping.fileName, eleAttrName: deviceTypesMapping.attName) { [weak self] contens in
            guard let self = self else { return }
            let irItems = contens.enumerated().map { (index,ele) in
                let type = IRType.allTypes[index]
                return DeviceTypeItem(type: type,name: ele.plainText, iconStr: IRType.modelsMappingType(type).icon, raw: ele)
            }
            self.dataSource = irItems
        }
    }
}

extension RemoteTypeListVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.dataSource.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell!.accessoryType = .disclosureIndicator
            cell!.imageView?.contentMode = .scaleAspectFit
            cell!.imageView?.autoLayoutWidth(40)
            cell!.imageView?.autoLayoutHeight(40)
            cell!.imageView?.autoPinLeading(constant: 16)
            cell!.textLabel?.autoPinLeadingToTrailingOfView(cell!.imageView!, constant: 16)
            cell!.imageView?.autoPinCenterY()
            cell!.textLabel?.autoPinCenterY()
            cell!.setSeperatorLineEnable()
        }
        let item = self.dataSource[indexPath.row]
        cell?.textLabel?.text = item.name
        cell?.imageView?.image = UIImage.SVGImage(named: item.iconStr)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = self.dataSource[indexPath.row]
        if item.type == IRType.DEVICE_REMOTE_CUSTOM {
            navigationController?.pushViewController(RemoteLearnVC.instance(hub3DeviceId: hub3DeviceId, remote: nil), animated: true)
        } else {
            navigationController?.pushViewController(RemoteListVC.instance(item.type, hub3DeviceId), animated: true)
        }
    }
}

extension RemoteTypeListVC {
    static func instance(_ hub3DeviceId: String) -> RemoteTypeListVC {
        let vc = RemoteTypeListVC(nibName: nil, bundle: nil)
        vc.hub3DeviceId = hub3DeviceId
        return vc
    }
}
