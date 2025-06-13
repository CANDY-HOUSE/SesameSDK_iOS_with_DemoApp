//
//  LongPressReorder.swift
//
//  Created by Cristian Sava on 27/11/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

/// Defines how much does the selected row will pop out of the table when starting reordering.
public enum SelectedRowScale: CGFloat {
    /// Selected row will pop out without scaling at all
    case none = 1.00
    /// Selected row will barely pop out of the table.
    case small = 1.01
    /// Selected row will visibly pop out of the table. This is the default value.
    case medium = 1.03
    /// Selected row will scale to be considerable big comparing to the other rows of the table.
    case big = 1.05
}

/// Defines how the UITableView will auto scroll if more table cells exist than the visible ones.
public enum ScrollBehaviour: Int {
    /// No autoscroll, the user has to scroll the table view.
    case none = 0
    /// Scroll automatically when the selected cell is near the screen border.
    case late = 3
    /// Scroll automatically when the selected cell is a few cells apart from the screen border.
    case early = 6
}

/**
 Notifications that allow configuring the reorder of rows
*/
@objc public protocol LongPressReorder {

    /**
     Will be called when the moving row changes its current position to a new position inside the table.

     - Parameter currentIndex: Current position of row inside the table
     - Parameter newIndex: New position of row inside the table
     */
    func positionChanged(currentIndex: IndexPath, newIndex: IndexPath)
    /**
     Will be called when reordering is done (long press gesture finishes).

     - Parameter initialIndex: Initial position of row inside the table, when the long press gesture starts
     - Parameter finalIndex: Final position of row inside the table, when the long press gesture finishes
     */
    func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath)

    /**
     Specify if the current selected row should be reordered via drag and drop.

     - Parameter atIndex: Position of row
     - Returns: True to allow selected row to be reordered, false if row should not be moved
     */
    func startReorderingRow(atIndex indexPath: IndexPath) -> Bool
    /**
     Specify if the targeted row can change its position.

     - Parameter atIndex: Position of row that is allowed to be swapped
     - Returns: True to allow row to change its position, false if row is imutable
     */
    func allowChangingRow(atIndex indexPath: IndexPath) -> Bool
}

// MARK: - UITableView wrapper for supporting drag and drop reorder

/**
 Offers cell reordering by wrapping functionality on top of an UITableView
 */
open class LongPressReorderTableView {

    /// The table which will support reordering of rows
    fileprivate(set) var tableView: UITableView
    /// Long press gesture recognizer
    private var longPress: UIGestureRecognizer?
    /// Optional delegate for overriding default behaviour. Normally a subclass of UI(Table)ViewController.
    public weak var delegate: LongPressReorder?
    /// Controls how the table will autoscroll, if at all.
    var scrollBehaviour: ScrollBehaviour
    /// Controls how much the selected row will "pop out" of the table.
    var selectedRowScale: SelectedRowScale

    /// Helper struct used to track parameters involved in drag and drop of table row
    fileprivate struct DragInfo {
        static var began: Bool = false
        static var cellSnapshot: UIView!
        static var initialIndexPath: IndexPath!
        static var currentIndexPath: IndexPath!
        static var cellAnimating: Bool = false
        static var cellMustShow : Bool = false
        static var allowScroll: Bool = true
    }

    /**
     Single designated initializer

     - Parameter tableView: Targeted UITableView
     - Parameter scrollBehaviour: defines how the table will autoscroll
     - Parameter selectedRowScale: defines how big the cell's pop out effect will be
     */
    public init(_ tableView: UITableView, scrollBehaviour: ScrollBehaviour = .none, selectedRowScale: SelectedRowScale = .medium) {
        self.tableView = tableView
        self.scrollBehaviour = scrollBehaviour
        self.selectedRowScale = selectedRowScale
    }

    // MARK: - Exposed actions

    /**
     Add a long press gesture recognizer to the table view, therefore enabling row reordering via drag and drop.
     */
    open func enableLongPressReorder() {
        guard longPress == nil else {
            return
        }
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGestureRecognized(_:)))
        tableView.addGestureRecognizer(longPress!)
    }

    /**
     Disable the row reordering via drag and drop by removing the gesture recognizer.
     */
    open func disableLongPressReorder() {
        // To prevent multiple calls to this function without a matching enableLongPressReorder()
        if let longPress = longPress {
            // longPress will be released
            tableView.removeGestureRecognizer(longPress)
        }
        longPress = nil
    }

    // MARK: - Long press gesture action

    @objc fileprivate func longPressGestureRecognized(_ gesture: UIGestureRecognizer) {
        let point = gesture.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)

//        L.d(" gesture.state", gesture.state )
        switch gesture.state {
        case .began:
            if let indexPath = indexPath {
                if !(delegate?.startReorderingRow(atIndex: indexPath) ?? true) {
                    break
                }
                DragInfo.began = true
                DragInfo.initialIndexPath = indexPath
                DragInfo.currentIndexPath = indexPath

                let cell = tableView.cellForRow(at: indexPath)!

                var center = cell.center
                DragInfo.cellSnapshot = snapshotFromView(cell)
                DragInfo.cellSnapshot.center = center
                DragInfo.cellSnapshot.alpha = 0

                tableView.addSubview(DragInfo.cellSnapshot)

                UIView.animate(withDuration: 0.25, animations: {
                    center.y = point.y
                    DragInfo.cellAnimating = true
                    DragInfo.cellSnapshot.center = center
                    DragInfo.cellSnapshot.transform = CGAffineTransform(scaleX: self.selectedRowScale.rawValue, y: self.selectedRowScale.rawValue)
                    DragInfo.cellSnapshot.alpha = 0.95

                    cell.alpha = 0
                }, completion: { (finished) in
                    if finished {
                        DragInfo.cellAnimating = false
                        if DragInfo.cellMustShow {
                            DragInfo.cellMustShow = false
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                cell.alpha = 1
                            })
                        } else {
                            cell.isHidden = true
                        }
                    }
                })
            }

        case .changed:
            guard DragInfo.began else {
                break
            }
            guard let indexPath = indexPath else {
                break
            }
            if !(delegate?.allowChangingRow(atIndex: indexPath) ?? true) {
                break
            }

            if scrollBehaviour != .none, DragInfo.allowScroll, let visibleRowsPaths = tableView.indexPathsForVisibleRows, visibleRowsPaths.count > 2 {
                var lastVisibleRowPath = visibleRowsPaths[visibleRowsPaths.count - 1]
                var newRow = lastVisibleRowPath.row + 1
                var scrollPosition = UITableView.ScrollPosition.bottom
                if DragInfo.cellSnapshot.center.y > point.y {
                    lastVisibleRowPath = visibleRowsPaths[0]
                    newRow = lastVisibleRowPath.row - 1
                    scrollPosition = UITableView.ScrollPosition.top
                }

                if (scrollPosition == .bottom && newRow < tableView.numberOfRows(inSection: indexPath.section)) ||
                    (scrollPosition == .top && newRow > 0) {
                    if abs(DragInfo.currentIndexPath.row - newRow) < scrollBehaviour.rawValue {
                        let scrollIndexPath = IndexPath(row: newRow, section: indexPath.section)
                        DragInfo.allowScroll = false
                        UIView.animate(withDuration: 0.2, animations: {
                            self.tableView.scrollToRow(at: scrollIndexPath, at: scrollPosition, animated: false)
                        }, completion: {finished in
                            DragInfo.allowScroll = true
                        })
                    }
                }
            }

            var center = DragInfo.cellSnapshot.center
            center.y = point.y
            DragInfo.cellSnapshot.center = center

            if indexPath != DragInfo.currentIndexPath {
                delegate?.positionChanged(currentIndex: DragInfo.currentIndexPath, newIndex: indexPath)

                tableView.moveRow(at: DragInfo.currentIndexPath, to: indexPath)
                DragInfo.currentIndexPath = indexPath
            }

        default:
            guard DragInfo.began else {
                break
            }
            DragInfo.began = false

            if let cell = tableView.cellForRow(at: DragInfo.currentIndexPath) {
                if !DragInfo.cellAnimating {
                    cell.isHidden = false
                    cell.alpha = 0
                } else {
                    DragInfo.cellMustShow = true
                }

                let currentIndexPath = DragInfo.currentIndexPath!
                let initialIndexPath = DragInfo.initialIndexPath!

                UIView.animate(withDuration: 0.25, animations: {
                    DragInfo.cellSnapshot.center = cell.center
                    DragInfo.cellSnapshot.transform = CGAffineTransform.identity
                    DragInfo.cellSnapshot.alpha = 0
                    cell.alpha = 1
                }, completion: { (_) in
                    DragInfo.cellSnapshot.removeFromSuperview()
                    DragInfo.cellSnapshot = nil
                    DragInfo.initialIndexPath = nil
                    DragInfo.currentIndexPath = nil
                })

                delegate?.reorderFinished(initialIndex: initialIndexPath, finalIndex: currentIndexPath)
            }

        }
    }

    private func snapshotFromView(_ view: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let snapshot: UIView = UIImageView(image: image)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0.0
        snapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        snapshot.layer.shadowRadius = 0.0
        snapshot.layer.shadowOpacity = 0.4

        return snapshot
    }
}

// MARK: - Default implementation of LongPressReorder notifications

/**
 Extension that implements default behaviour for LongPressReorder notifications
 */
extension UIViewController: LongPressReorder {

    /**
     Default implementation: does nothing.

     - Parameter currentIndex: Current position of row inside the table
     - Parameter newIndex: New position of row inside the table
     */
    open func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
    }

    /**
     Default implementation: does nothing.

     - Parameter initialIndex: Initial position of row inside the table, when the long press gesture starts
     - Parameter finalIndex: Final position of row inside the table, when the long press gesture finishes
     */
    open func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
    }

    /**
     Default implementation: every table row can be moved.

     - Parameter atIndex: Position of row
     - Returns: True to allow selected row to be reordered, false if row should not be moved
     */
    open func startReorderingRow(atIndex indexPath: IndexPath) -> Bool {
        return true
    }

    /**
     Default implementation: every table row can be swaped against the current moving row.

     - Parameter atIndex: Position of row that is allowed to be swapped
     - Returns: True to allow row to change its position, false if row is imutable
     */
    open func allowChangingRow(atIndex indexPath: IndexPath) -> Bool {
        return true
    }
}
