//
//  Hub3IRDeviceBrandModelsVC.swift
//  SesameUI
//
//  Created by eddy on 2024/1/26.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

private extension String {
    var firstLetter: String {
        let mutableString = NSMutableString.init(string: self)
        CFStringTransform(mutableString as CFMutableString, nil, kCFStringTransformToLatin, false)
        let pinyinString = mutableString.folding(options: String.CompareOptions.diacriticInsensitive, locale: NSLocale.current)
        let strPinYin = pinyinString.uppercased()
        let firstString = String(strPinYin[..<strPinYin.index(strPinYin.startIndex, offsetBy: 1)])
        let regexA = "^[A-Z]$"
        let predA = NSPredicate.init(format: "SELF MATCHES %@", regexA)
        return predA.evaluate(with: firstString) ? firstString : "#"
    }
}

private let BOTTOM_BUTTON_HEIGHT = 60.0
class Hub3IRDeviceBrandModelsVC: CHBaseViewController {
    var deviceType: Int
    var device: CHHub3!
    private var tableViewTopConstraint: NSLayoutConstraint?

    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.sectionIndexColor = .sesame2Green
        table.backgroundColor = .white
        table.rowHeight = 50
        table.sectionHeaderHeight = 45
        table.sectionFooterHeight = 0
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    lazy var searchController: UISearchController = {
        let searchControl = UISearchController(searchResultsController: nil)
        searchControl.obscuresBackgroundDuringPresentation = false
        searchControl.searchBar.placeholder = "co.candyhouse.sesame2.ir_search_remote_control_notice".localized
        searchControl.searchBar.sizeToFit()
        return searchControl
    }()
    
    lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = navigationController?.navigationBar.barTintColor
        if textView.backgroundColor == nil {
            textView.backgroundColor = UIColor(rgb: 0xf2f2f7)
        }
        textView.textColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.6)
        textView.font = .systemFont(ofSize: 14)
        textView.text = "co.candyhouse.sesame2.ir_company_notice".localized
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16)
        return textView
    }()
    
    lazy var allModels = [IRRemote]()
    var filteredModels: [IRRemote] = []
    var isSearchActive: Bool {
        return searchController.isActive && !searchController.searchBar.text!.isEmpty
    }
    var modelGroupsTuple: (titles: [String], modelsDict: [String: [IRRemote]]) = ([], [:]) {
        didSet {
            allModels = modelGroupsTuple.modelsDict.values.flatMap({ $0 })
            tableView.reloadData()
        }
    }
    
    init(deviceType: Int, device: CHHub3) {
        self.deviceType = deviceType
        self.device = device
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTable()
        loadModelData()
    }
    
    func configureTable() {
        view.addSubview(descriptionTextView)
        view.addSubview(tableView)
        
        // 设置背景色
        view.backgroundColor = .white
        
        // 设置约束
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 保存 tableView 的顶部约束引用
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor)
        
        NSLayoutConstraint.activate([
            // descriptionTextView 约束
            descriptionTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // tableView 约束
            tableViewTopConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 设置 TableView 的其他属性
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        definesPresentationContext = true
        
//        view.addSubview(quickMatchView)
//        quickMatchView.autoPinBottom()
//        quickMatchView.autoPinTrailing()
//        quickMatchView.autoPinWidth()
//        quickMatchView.heightConstraint?.constant = BOTTOM_BUTTON_HEIGHT
//        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: BOTTOM_BUTTON_HEIGHT - view.safeAreaInsets.bottom, right: 0)
//
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGRectGetHeight(keyboardSize), right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.safeAreaInsets.bottom, right: 0)
    }
    
    func loadModelData() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let name = self.getIRRomteFileName(self.deviceType)
            guard !name.isEmpty else {
                L.d("IRRemote", "IR remote file name is empty")
                return
            }
            var irRemoteList: [IRRemote] = []
            guard BaseUtils.loadJsonArray(name, result: &irRemoteList) else {
                L.d("IRRemote", "Failed to load JSON array")
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                var modelsMapping = [String: [IRRemote]]()
                var nameKeys = [String]()
                
                irRemoteList.forEach { model in
                    let direction = model.direction.isEmpty ? "#" : model.direction
                    if modelsMapping[direction] == nil {
                        modelsMapping[direction] = []
                    }
                    modelsMapping[direction]?.append(model)
                }
                nameKeys = Array(modelsMapping.keys).sorted()
                if nameKeys.contains("#") {
                    nameKeys.removeAll { $0 == "#" }
                    nameKeys.append("#")
                }
                
                executeOnMainThread { [weak self] in
                    guard let self = self else { return }
                    self.modelGroupsTuple = (nameKeys, modelsMapping)
                }
            }
        }
    }
    
    func getIRRomteFileName(_ type: Int) -> String {
        switch type {
        case IRDeviceType.DEVICE_REMOTE_AIR:       return "air_control_type"
        case IRDeviceType.DEVICE_REMOTE_TV:        return "tv_control_type"
        case IRDeviceType.DEVICE_REMOTE_LIGHT:     return "light_control_type"
        default:
            return ""
        }
    }
    
    func handleGotoRemoteController(_ irRemote: IRRemote) {
        let handler = IRDeviceType.controlFactory(deviceType, nil)
        if let provider = handler as? ControlAirRemote {
            provider.setAirData(typeCode: irRemote.code)
            device.preference.updateSelectExpandIndex(-1)
        }
        irRemote.type = deviceType
        irRemote.haveSave = false
        let vc = Hub3IRRemoteControlVC(irRemote: irRemote)
        vc.chDevice = device
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension Hub3IRDeviceBrandModelsVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredModels = allModels.filter { model in
                model.model.lowercased().contains(searchText.lowercased()) ||
                model.alias.lowercased().contains(searchText.lowercased())
            }
        } else {
            filteredModels = allModels
        }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension Hub3IRDeviceBrandModelsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let displayedSource = isSearchActive ? filteredModels : modelGroupsTuple.modelsDict[modelGroupsTuple.titles[indexPath.section]]!
        let selectedItem = displayedSource[indexPath.row]
        handleGotoRemoteController(selectedItem)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearchActive ? 1 : modelGroupsTuple.titles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchActive {
            return filteredModels.count
        }
        let sectionKey = modelGroupsTuple.titles[section]
        return modelGroupsTuple.modelsDict[sectionKey]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isSearchActive ? "co.candyhouse.sesame2.ir_search_result".localized : modelGroupsTuple.titles[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
            cell!.textLabel?.font = .systemFont(ofSize: 15)
            cell!.textLabel?.numberOfLines = 0
            cell!.textLabel?.lineBreakMode = .byWordWrapping
            cell!.textLabel?.minimumScaleFactor = 0.5
            cell!.setSeperatorLineEnable(trailingConstant: -16)
        }
        let irRemote = isSearchActive ? filteredModels[indexPath.row] : modelGroupsTuple.modelsDict[modelGroupsTuple.titles[indexPath.section]]![indexPath.row]
        
        if isSearchActive, let searchText = searchController.searchBar.text, !searchText.isEmpty {
            // 创建富文本
            let attributedString = NSMutableAttributedString(string: irRemote.alias)
            let range = (irRemote.alias.lowercased() as NSString).range(of: searchText.lowercased())
            
            // 设置默认颜色
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.black,
                                          range: NSRange(location: 0, length: irRemote.alias.count))
            // 设置匹配文字的颜色
            if range.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor,
                                              value: UIColor.sesame2Green,
                                              range: range)
            }
            cell!.textLabel?.attributedText = attributedString
        } else {
            cell!.textLabel?.text = irRemote.alias
            cell!.textLabel?.textColor = .black
        }
        return cell!
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return isSearchActive ? nil : modelGroupsTuple.titles
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return modelGroupsTuple.titles.firstIndex(of: title) ?? -1
    }
}

// MARK: - UISearchControllerDelegate
extension Hub3IRDeviceBrandModelsVC: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        UIView.animate(withDuration: 0.3) {
            self.descriptionTextView.alpha = 0
            self.tableViewTopConstraint?.isActive = false
            self.tableViewTopConstraint = self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
            self.tableViewTopConstraint?.isActive = true
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.descriptionTextView.isHidden = true
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        self.descriptionTextView.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.descriptionTextView.alpha = 1
            self.tableViewTopConstraint?.isActive = false
            self.tableViewTopConstraint = self.tableView.topAnchor.constraint(equalTo: self.descriptionTextView.bottomAnchor)
            self.tableViewTopConstraint?.isActive = true
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - Factory Method
extension Hub3IRDeviceBrandModelsVC {
    static func instance(_ deviceType: Int, _ device: CHHub3) -> Hub3IRDeviceBrandModelsVC {
        let vc = Hub3IRDeviceBrandModelsVC(deviceType: deviceType, device: device)
        vc.device = device
        return vc
    }
}
