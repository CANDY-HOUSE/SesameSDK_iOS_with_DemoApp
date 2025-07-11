//
//  TableProxy.swift
//  SesameUI
//  全局 TableView Proxy
//  Created by eddy on 2023/11/30.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

// 约定单页容量
let PageSize: Int = 10

public struct CHCellDescriptor {
    public let cellCls: AnyClass
    public let rawValue: Any!
    let configure: (_ UITableViewCell: CellConfiguration) -> Void
}

class CHTableViewProxy: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var dataSource: [CHCellDescriptor] = [CHCellDescriptor]()
    private var registeredCells: [String: String] = [:]
    public private(set) weak var tableView: UITableView!
    private weak var superView: UIView!
    var selectHandler: (CHCellDescriptor, IndexPath) -> Void
    private var refreshHeaderHandler: () -> Void?
    
    required init(style: UITableView.Style = .plain,
                  superView: UIView,
                  selectHandler:  @escaping (CHCellDescriptor, IndexPath) -> Void,
                  emptyPlaceholder: String?,
                  richPlaceholder: NSAttributedString? = nil) {
        self.selectHandler = selectHandler
        self.refreshHeaderHandler = {}
        super.init()
        self.superView = superView
        let tableView = UITableView.ch_tableView(superView, style, emptyPlaceholder ?? "", richPlaceholder)
        self.tableView = tableView
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    /// 註冊cell
    /// - Parameter descriptor: descriptor
    func registCells(_ cellCls: AnyClass) {
        let identifier = NSStringFromClass(cellCls)
        guard self.registeredCells[identifier] == nil else { return }
        self.tableView.register(UINib(nibName: NSStringFromClass(cellCls), bundle: nil),forCellReuseIdentifier: identifier)
        self.registeredCells[identifier] = NSStringFromClass(cellCls)
    }
    
    deinit {
        registeredCells.removeAll()
        dataSource.removeAll()
    }
}

/// 數據源、動態註冊cell
extension CHTableViewProxy {
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row <= dataSource.count - 1 else { return UITableViewCell() }
        let cellDiscriptor = dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(cellDiscriptor.cellCls), for: indexPath)
        cellDiscriptor.configure(cell as! CellConfiguration)
        cell.selectionStyle = .none
        return cell
    }
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row <= dataSource.count - 1 else { return }
        let cellDiscriptor = dataSource[indexPath.row]
        selectHandler(cellDiscriptor, indexPath)
    }
}

extension CHTableViewProxy {
    
    /// 處理成功數據源
    /// - Parameters:
    ///   - items: CellConfiguration 數據
    ///   - descriptors: CHCellDescriptor 數據
    ///   - isLoadMore: 是否加載更多
    func handleSuccessfulDataSource(_ items: [CellConfiguration]?, _ descriptors: [CHCellDescriptor] = [CHCellDescriptor](), isLoadMore: Bool = false) {
        
        @discardableResult
        func appendItemHandler() -> Int {
            let isDescriptor = !descriptors.isEmpty
            if isDescriptor {
                for item in descriptors {
                    self.dataSource.append(item)
                }
            } else {
                for item in items ?? [CellConfiguration]() {
                    let descriptor = CHCellDescriptor(cellCls: item.cellCls!, rawValue: item) { cell in
                        cell.configure(item: item)
                    }
                    self.dataSource.append(descriptor)
                }
            }
            return isDescriptor ? descriptors.count : items?.count ?? 0
        }
        // 注册
        var appendedCount = 0
        if isLoadMore {
            appendedCount = appendItemHandler()
        } else {
            self.dataSource.removeAll()
            appendedCount = appendItemHandler()
        }
        self.dataSource.forEach { item in
            self.registCells(item.cellCls)
        }
        self.reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            guard self.tableView != nil else { return }
            appendedCount != PageSize ? self.tableView.refreshFootView?.noMoreData() : self.tableView.refreshFootView?.endRefresh()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    /// 刷新TableView
    func reload() {
        // 刷新
        tableView.reloadData()
        tableView.backgroundView?.isHidden = !dataSource.isEmpty
    }
    
    /// 處理失敗數據源
    /// - Parameter err: 錯誤對象
    func handleFailedDataSource(_ err: Error) {
        endRefreshWithNoMoreData()
        superView.makeToast(err.errorDescription())
    }
    
    /// 配置表頭表尾
    /// - Parameters:
    ///   - headerHandler: 表頭 refresh 處理
    ///   - footerHandler: 表尾 loadmore 處理
    func configureTableHeader(_ headerHandler: (() -> Void)?, _ footerHandler: (() -> Void)?) {
        if headerHandler != nil {
            refreshHeaderHandler = headerHandler!
            tableView.refreshControl?.addRefreshHandler(headerHandler!)
        } else {
            tableView.refreshControl = nil
        }
        if footerHandler != nil {
            tableView.refreshFootView(refresh: footerHandler!)
            self.tableView.refreshFootView?.refreshState = .NoMoreData
        }
    }
    
    /// 結束刷新並設置為無更多數據
    func endRefreshWithNoMoreData() {
        tableView.refreshControl?.endRefreshing()
        tableView.refreshFootView?.endRefresh()
        tableView.refreshFootView?.noMoreData()
        reload()
    }
    
    
    /// 刷新
    func refresh() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let refreshController = self.tableView.refreshControl else { return }
            refreshController.beginRefreshing()
            var pt = self.tableView.contentOffset
            pt.y -= refreshController.frame.size.height / 2
            self.tableView.setContentOffset(pt, animated: true)
            refreshController.sendActions(for: .valueChanged)
        }
    }
}

extension UITableView {
    
    /// 創建一個 帶表頭的 TableView
    /// - Parameters:
    ///   - superView: 父視圖
    ///   - style: 類型
    ///   - placeholder: 空數據狀態占位
    ///   - richDesc: 富文本占位
    /// - Returns: TableView
    static func ch_tableView(_ superView: UIView ,_ style: Style = .plain, _ placeholder: String = "", _ richDesc: NSAttributedString? = nil, _ refresh: Bool = true) -> UITableView {
        let tableView = UITableView(frame: superView.bounds, style: style)
        superView.addSubview(tableView)
        tableView.autoPinLeading()
        tableView.autoPinTrailing()
        tableView.autoPinTopToSafeArea()
        tableView.autoPinBottom()
        tableView.setupEmptyDataView(placeholder, richDesc)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refresh ? UIRefreshControl() : nil
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }
    
    /// 配置 data 為空的數據
    /// - Parameters:
    ///   - title: 普通文本
    ///   - richDesc: 富文本
    fileprivate func setupEmptyDataView(_ title: String, _ richDesc: NSAttributedString?) {
        let emptyDataView = UIView(frame: self.bounds)
        let emptyDataLabel = UILabel()
        emptyDataLabel.numberOfLines = 0 //允許換行
        emptyDataLabel.lineBreakMode = .byWordWrapping //以單字換行
        emptyDataLabel.translatesAutoresizingMaskIntoConstraints = false
        if richDesc != nil {
            emptyDataLabel.attributedText = richDesc
        } else {
            emptyDataLabel.textAlignment = .center
            emptyDataLabel.textColor = UIColor.placeHolderColor
            emptyDataLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            emptyDataLabel.text = title
        }
        emptyDataView.addSubview(emptyDataLabel)
        NSLayoutConstraint.activate([
            emptyDataLabel.centerXAnchor.constraint(equalTo: emptyDataView.centerXAnchor),
            emptyDataLabel.centerYAnchor.constraint(equalTo: emptyDataView.centerYAnchor, constant: -50),
            emptyDataLabel.leadingAnchor.constraint(equalTo: emptyDataView.leadingAnchor, constant: 20),
            emptyDataLabel.trailingAnchor.constraint(equalTo: emptyDataView.trailingAnchor, constant: -20)
            // 使UILabel的左右边距保持20点的距离，这样可以确保UILabel的宽度在屏幕尺寸变化时能够正确地调整。如果文本长度超过UILabel的宽度，它应该会自动换行。
        ])
        self.backgroundView = emptyDataView
    }
}

private var refreshControlHandlerKey: UInt8 = 0
// 創建 block 回調的關聯對象
extension UIRefreshControl {
    private var refreshHandler: (() -> Void)? {
        get {
            return objc_getAssociatedObject(self, &refreshControlHandlerKey) as? () -> Void
        }
        set {
            objc_setAssociatedObject(self, &refreshControlHandlerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    fileprivate func addRefreshHandler(_ handler: @escaping () -> Void) {
        self.refreshHandler = handler
        self.addTarget(self, action: #selector(runHandler), for: .valueChanged)
    }
    
    @objc private func runHandler() {
        refreshHandler?()
    }
}
