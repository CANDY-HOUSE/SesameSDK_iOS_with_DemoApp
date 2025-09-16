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



// MARK: - Main View Controller
class Hub3IRRemoteMatchControlVC: CHBaseViewController, ShareAlertConfigurator {
    
    public private(set) var viewModel: Hub3IRRemoteMatchViewModel!
    private weak var guidView: FloatingTipView?
    private var tableViewTopConstraint: NSLayoutConstraint?
    
    typealias MatchCompletionHandler = (Bool, IRRemote?, [MatchIRRemote]?) -> Void
    var matchCompletionHandler: MatchCompletionHandler?
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.sectionIndexColor = .sesame2Green
        table.backgroundColor = .white
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 50
        table.sectionHeaderHeight = 45
        table.sectionFooterHeight = 0
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        return table
    }()
    
    private lazy var searchingView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.isHidden = true
        
        let label = UILabel()
        label.text = "co.candyhouse.hub3.ir_auto_searching_remote".localized
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 0
        
        containerView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        return containerView
    }()
    
    init(viewModel: Hub3IRRemoteMatchViewModel!) {
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
    
    func configureNavTitle() {
        setNavigationBarSubtitle(title: viewModel.getInitIrRemoteDevice()?.model ?? "", subtitle: nil) { [weak self] in
            // 处理导航栏点击事件
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavTitle()
        configureGuidView()
        configureTable()
        configureViewModel()
        viewModel.getIRMode()
    }
    
    func configureGuidView() {
        guard guidView == nil else { return }
        let emptyHit = "co.candyhouse.hub3.air_match_introduction".localized
        let floatView = FloatingTipView.showIn(superView: view,
                                               style: .topImageWithTextCompact(imageName: "co.candyhouse.hub3.ir_auto_match_introduce", text: emptyHit))
        
        floatView.backgroundColor = .white
        self.guidView = floatView
    }
    
    func configureTable() {
        view.addSubview(tableView)
        view.addSubview(searchingView)
        
        // 设置背景色
        view.backgroundColor = .white
        
        // 设置约束
        tableView.translatesAutoresizingMaskIntoConstraints = false
        searchingView.translatesAutoresizingMaskIntoConstraints = false
        
        // 确保 guidView 存在后再设置约束
        if let guidView = self.guidView {
            tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: guidView.bottomAnchor)
        } else {
            // 如果没有引导视图，则约束到安全区域
            tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        }
        
        NSLayoutConstraint.activate([
            tableViewTopConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            searchingView.topAnchor.constraint(equalTo: tableView.topAnchor),
            searchingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func configureViewModel() {
        viewModel.viewDidLoad()
        viewModel.observeIRMatchItemList { [weak self] matchList in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                L.d("UI Update", "TableView reloaded with \(matchList.count) items")
            }
        }
        viewModel.observeSearchingState { [weak self] isSearching in
            DispatchQueue.main.async {
                self?.updateSearchingViewVisibility()
                L.d("UI Update", "Searching state: \(isSearching)")
            }
        }
    }
    
    private func updateSearchingViewVisibility() {
        let shouldShowSearching = viewModel.isSearching && viewModel.irMatchItemList.isEmpty
        searchingView.isHidden = !shouldShowSearching
        
        // 如果显示搜索视图，将其置于最前面
        if shouldShowSearching {
            view.bringSubviewToFront(searchingView)
        }
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension Hub3IRRemoteMatchControlVC: UITableViewDelegate, UITableViewDataSource  {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.irMatchItemList.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 处理选中事件
        let irRemote = viewModel.irMatchItemList[indexPath.row]
        // 执行相应的操作
        self.matchCompletionHandler?(true,irRemote.remote ,nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "IRRemoteCell"
            var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            
            if cell == nil {
                // 使用 .value1 样式，自动支持左侧主标题和右侧详细信息
                cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
                cell!.textLabel?.font = .systemFont(ofSize: 15)
                cell!.textLabel?.numberOfLines = 0
                cell!.textLabel?.lineBreakMode = .byWordWrapping
                
                // 设置右侧详细标签的样式
                cell!.detailTextLabel?.font = .systemFont(ofSize: 14)
                cell!.detailTextLabel?.textColor = .black
                
                cell!.setSeperatorLineEnable(trailingConstant: -16)
            }
            
            let irRemote = viewModel.irMatchItemList[indexPath.row]
            
            cell!.textLabel?.text = irRemote.remote.alias
            cell!.textLabel?.textColor = .black
            
            cell!.detailTextLabel?.text = "\(irRemote.matchPercent)%"
            
            return cell!
    }
}


extension Hub3IRRemoteMatchControlVC {
    static func instance(hub3DeviceId: String,
                         irReomte: IRRemote,
                         existingMatchList: [MatchIRRemote]? = nil,
                         completion: @escaping (Bool, IRRemote?, [MatchIRRemote]?) -> Void = { _, _, _ in }
    ) -> Hub3IRRemoteMatchControlVC {
        let vc =  Hub3IRRemoteMatchControlVC(viewModel: Hub3IRRemoteMatchViewModel(hub3DeviceId: hub3DeviceId,irRemote: irReomte, existingMatchList: existingMatchList))
        vc.matchCompletionHandler = { success, irRemote, _ in
            completion(success, irRemote, vc.viewModel.irMatchItemList)
        }
        return vc
    }
}
