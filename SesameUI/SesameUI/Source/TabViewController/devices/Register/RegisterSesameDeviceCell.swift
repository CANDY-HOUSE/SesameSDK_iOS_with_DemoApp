import UIKit

class RegisterSesameDeviceCell: UITableViewCell {
    @IBOutlet weak var deviceTypeLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel! {
        didSet {
            rssiLabel.textColor = .sesame2Green
        }
    }
    @IBOutlet weak var rssiImageView: UIImageView!
    @IBOutlet weak var sesame2DeviceIdLabel: UILabel!
    @IBOutlet weak var sesame2StatusLabel: UILabel! {
        didSet {
            sesame2StatusLabel.textColor = UIColor.sesame2LightGray
        }
    }
    var indexPath: IndexPath!
}
