//
//  CHTableView.swift
//  SesameUI
//
//  Created by tse on 2023/6/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit


class CHTableView : UITableView {


    var k_delegate : KTableViewDelegate? = nil

    lazy var refreshController: UIRefreshControl = {
        let ctl = UIRefreshControl()
        ctl.attributedTitle = NSAttributedString(string: "下载刷新")
        ctl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        return ctl
    }()

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        initSubView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubView()
    }

    private var context = 0

    func initSubView() {
        self.addSubview(refreshController)
        addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.new, context: &context)
    }

    @objc func onRefresh(){
        k_delegate?.onRerefresh(tableView: self)
    }

    func startRefresh(){
        refreshController.beginRefreshing()
    }

    func endRefresh(){
        refreshController.endRefreshing()
    }

    private var firstVisible = -1
    private var lastVisible = -1

    func checkChanged(first:Int , last:Int) -> Bool{
        let result = lastVisible != last || first != firstVisible
        self.firstVisible = first
        self.lastVisible = last
        return result
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            var first = -1,last = -1
            let cells = self.visibleCells
            if let cell = cells.first{
                first = self.indexPath(for: cell)?.row ?? -1
            }
            if let cell = cells.last{
                last = self.indexPath(for: cell)?.row ?? -1
            }
            if checkChanged(first: first, last: last){
                onVisibleCellChange(first: first, last: last)
            }
        }
    }

    var isLoadMore = false

    func onVisibleCellChange(first:Int,last:Int){
        NSLog("第一个可见 : \(first), 最后可见 : \(last)")
        k_delegate?.onVisibleCellChange(tableView: self, first: first, last: last)
        let number = self.numberOfRows(inSection: 0)
        NSLog("总数量 \(number)")
        if last == number - 1 && !refreshController.isRefreshing {
            startLoadMore()
        }
    }

    func startLoadMore(){
        loadMore()
    }

    private func loadMore(){
        if isLoadMore {
            return
        }

        isLoadMore = true
        k_delegate?.onLoadMore(tableView: self)
    }

    func endLoadMore(){
        isLoadMore = false
    }
}

protocol KTableViewDelegate {
    func onRerefresh(tableView:CHTableView)

    func onLoadMore(tableView:CHTableView)

    func onVisibleCellChange(tableView:CHTableView,first:Int,last:Int)
}

extension KTableViewDelegate{

    func onVisibleCellChange(tableView:CHTableView,first:Int,last:Int) {

    }

}
