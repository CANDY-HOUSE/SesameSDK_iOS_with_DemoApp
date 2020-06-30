// Copyright 2018, Ralf Ebert
// License   https://opensource.org/licenses/MIT
// License   https://creativecommons.org/publicdomain/zero/1.0/
// Source    https://www.ralfebert.de/ios-examples/uikit/choicepopover/

import UIKit

//class ArrayChoiceTableViewController<Element> : UITableViewController {
//    
//    typealias SelectionHandler = (Element) -> Void
//    typealias LabelProvider = (Element) -> String
//    
//    private let values : [Element]
//    private let labels : LabelProvider
//    private let onSelect : SelectionHandler?
//    
//    init(_ values : [Element], labels : @escaping LabelProvider = String.init(describing:), onSelect : SelectionHandler? = nil) {
//        self.values = values
//        self.onSelect = onSelect
//        self.labels = labels
//        super.init(style: .plain)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return values.count
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
//        cell.textLabel?.text = labels(values[indexPath.row])
//        return cell
//    }
//    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        self.dismiss(animated: true)
//        onSelect?(values[indexPath.row])
//    }
//    
//}
