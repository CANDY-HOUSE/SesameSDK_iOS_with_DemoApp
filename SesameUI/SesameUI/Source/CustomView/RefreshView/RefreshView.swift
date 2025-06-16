//
//  RefreshView.swift
//  Eat
//
//  Created by YI on 2020/11/26.
//

import UIKit

extension UIScrollView {
    struct AssociatedKeys {
        static var refreshHeaderView: String = "RefreshHeaderView"
        static var refreshFootView: String = "RefreshFootView"
    }
    
    
    /// 头部刷新控件
    var refreshHeaderView: RefreshHeaderView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.refreshHeaderView) as? RefreshHeaderView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.refreshHeaderView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 头部刷新方法
    /// - Parameter refresh: 刷新回调
    func refreshHeaderView(refresh: @escaping () -> Void, style: LoadingStyle? = LoadingStyle.activityIndicator) {
        self.refreshHeaderView = RefreshHeaderView.headerView(refresh: refresh, scrollView: self)
        self.addSubview(self.refreshHeaderView!)
    }
    
    /// 底部刷新控件
    var refreshFootView: RefreshFootView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.refreshFootView) as? RefreshFootView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.refreshFootView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 底部刷新方法
    /// - Parameter refresh: 刷新回调
    func refreshFootView(refresh: @escaping () -> Void, style: LoadingStyle? = LoadingStyle.activityIndicator) {
        self.refreshFootView = RefreshFootView.footView(refresh: refresh, scrollView: self)
        self.addSubview(self.refreshFootView!)
    }
    
}


enum RefreshState {
    case Ready //准备状态
    case WillRefresh //即将进入刷新
    case Refreshing //刷新中
    case Refreshed //刷新完成
    case NoMoreData //没有更多数据

}

class RefreshView: UIView {

    static var contentOffsetKeyPath = "contentOffset"
    static var contentSizeKeyPath = "contentSize"
    static var boundsKeyPath = "bounds"
    
    var loadingStyle: LoadingStyle!

    weak var scrollView: UIScrollView?
    /// 刷新回调
    var refresh: (() -> Void)? = nil
    
    
    /// 是否可以刷刷
    var canRefresh: Bool?
    /// 提示label
    var tipsLabel: UILabel?
    /// 正在刷新、加载更多的view
    var loadingView: UIView?
    
    /// 刷新状态
    var refreshState: RefreshState?
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
//            newSuperview?.bounds
            newSuperview!.addObserver(self, forKeyPath: RefreshView.contentOffsetKeyPath, options: .new, context: nil)
            newSuperview!.addObserver(self, forKeyPath: RefreshView.boundsKeyPath, options: [.new, .old], context: nil)
        }
    }
    
}




