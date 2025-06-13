//
//  RefreshFootView.swift
//  Eat
//
//  Created by YI on 2020/11/27.
//

import UIKit

class RefreshFootView: RefreshView {

    override var refreshState: RefreshState? {
        willSet {
//            L.d("refreshState",refreshState)
            tipsLabel?.isHidden = false
            loadingView?.isHidden = true
            if newValue == .Ready  {
                tipsLabel?.text = "candyhouse.pull_up_to_load".localized
                //                tipsLabel?.textColor = .lockRed
            }else if newValue == .WillRefresh  {
                tipsLabel?.text = "candyhouse.release_to_refresh".localized
                //                tipsLabel?.textColor = .lockRed
            }else if newValue == .Refreshing {
                tipsLabel?.isHidden = true
                loadingView?.isHidden = false
                //                tipsLabel?.textColor = .lockRed
            }else {
                tipsLabel?.text = "candyhouse.no_data".localized
//                tipsLabel?.textColor = .lockRed  如果要改颜色。各状态都要改
            }
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.tipsLabel?.frame = self.bounds
        self.loadingView?.center = .init(x: self.center.x, y: self.frame.size.height / 2.0)
    }
    
    
    /// 初始化footView
    /// - Parameters:
    ///   - refresh: 刷新回调
    ///   - scrollView: scrollView
    /// - Returns: footView
    class func footView(refresh: @escaping () -> Void, scrollView: UIScrollView, style: LoadingStyle = .activityIndicator) -> RefreshFootView {
        let footH: CGFloat = 50
        let footView = RefreshFootView.init(frame: .init(x: 0, y: 0, width: scrollView.frame.size.width, height: footH))
        footView.loadingStyle = style
        footView.scrollView = scrollView
        footView.refresh = refresh
        footView.setSubviews()
        
        scrollView.addObserver(footView, forKeyPath: RefreshView.contentSizeKeyPath, options: .new, context: nil)
        
        return footView
    }
    
    /// 设置子view
    func setSubviews() {
        self.tipsLabel = UILabel.init()
        self.tipsLabel?.text = ""
        self.tipsLabel?.textColor = .black
        self.tipsLabel?.textAlignment = .center
        self.tipsLabel?.backgroundColor = .clear
        self.addSubview(self.tipsLabel!)
        
        let w: CGFloat = 30
        self.loadingView = IndicatorGenerator.indicator(style: loadingStyle)
        self.loadingView?.isHidden = true
        self.loadingView?.frame.size.width = w
        self.loadingView?.frame.size.height = w
        self.loadingView?.center = .init(x: self.center.x, y: self.frame.size.height / 2.0)
        self.addSubview(self.loadingView!)
    }
    
    /// KVO监听contentOffset、contentSize、bounds的变化
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == RefreshView.contentOffsetKeyPath {
            if self.canRefresh == true && self.scrollView!.isDragging == false {
                if self.refreshState == .WillRefresh {
                    //松手进入刷新状态
                    self.refreshState = .Refreshing
                    if self.refresh != nil {
                        self.refresh!()
                    }
                    
                    var bottom: CGFloat = 0
                    if self.scrollView!.contentSize.height > self.scrollView!.frame.size.height {
                        //内容高度超出了scrollView的高度
                        bottom = self.frame.size.height
                    }else {
                        //内容高度低于scrollView的高度
                        bottom = self.scrollView!.frame.size.height + self.frame.size.height - self.scrollView!.contentSize.height
                    }
                    
                    UIView.animate(withDuration: 0.5) {
                        self.scrollView?.contentInset.bottom = bottom
                    }
                }
            }
            
            if self.scrollView!.isDragging == true {
                if self.refreshState != .Refreshing && self.refreshState != .NoMoreData  {
                    //非刷新状态下拖拽scrollView
                    if self.scrollView!.contentSize.height > self.scrollView!.frame.size.height {
                        //内容高度超出了scrollView的高度
                        if (self.scrollView!.contentOffset.y + self.scrollView!.frame.size.height) >= (self.scrollView!.contentSize.height + self.frame.size.height + 5) {
                            self.refreshState = .WillRefresh
                            self.canRefresh = true
                        }else {
                            self.refreshState = .Ready
                            self.canRefresh = false
                        }
                    }else {
                        //内容高度低于scrollView的高度
                        if self.scrollView!.contentOffset.y >= self.frame.size.height + 5 {
                            self.refreshState = .WillRefresh
                            self.canRefresh = true
                        }else {
                            self.refreshState = .Ready
                            self.canRefresh = false
                        }
                    }
                }
                
            }
        }else if keyPath == RefreshView.contentSizeKeyPath {
            //内容高度发生改变，改变footView的y值
            self.frame.origin.y = self.scrollView!.contentSize.height
            var bottom: CGFloat = 0
            if self.scrollView!.contentSize.height > self.scrollView!.frame.size.height {
                bottom = self.frame.size.height
            }else {
                bottom = self.scrollView!.frame.size.height + self.frame.size.height - self.scrollView!.contentSize.height
            }
            self.scrollView?.contentInset.bottom = bottom
        }else if keyPath == RefreshView.boundsKeyPath {
            //scrollView的bound发生改变
            let newValue: CGRect = change?[NSKeyValueChangeKey.newKey] as? CGRect ?? .zero
            let oleValue: CGRect = change?[NSKeyValueChangeKey.oldKey] as? CGRect ?? .zero
            if newValue.size.width != oleValue.size.width {
                self.frame.size.width = newValue.size.width
            }
        }
    }
    
    
    /// 停止刷新
    func endRefresh() {
        self.scrollView?.contentInset = .zero
        self.refreshState = .Ready
    }
    
    /// 没有更多数据
    func noMoreData() {
        self.refreshState = .NoMoreData
    }
    
    /// 重置没有更多数据的状态
    func resetNoMoreData() {
        if self.refreshState == .NoMoreData {
            self.refreshState = .Ready
            self.scrollView?.contentInset = .zero
        }
    }
    
    deinit {
        if self.scrollView != nil {
            self.scrollView!.removeObserver(self, forKeyPath: RefreshView.contentOffsetKeyPath, context: nil)
            self.scrollView!.removeObserver(self, forKeyPath: RefreshView.contentSizeKeyPath, context: nil)
            self.scrollView!.removeObserver(self, forKeyPath: RefreshView.boundsKeyPath, context: nil)
        }
 
    }

}
