import UIKit
import SesameSDK

@objc(RegisterSesameDeviceCell)
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }
}


extension RegisterSesameDeviceCell: CellConfiguration {
    func configure<T>(item: T) {
        guard let device = item as? CHDevice else { return }
        rssiLabel.text = "\(device.currentDistanceInCentimeter()) \("co.candyhouse.sesame2.cm".localized)"
        sesame2DeviceIdLabel.text = device.deviceId.uuidString
        sesame2StatusLabel.text = device.deviceStatusDescription()
        rssiImageView.image = UIImage.SVGImage(named: "bluetooth",fillColor: .sesame2Green)
        deviceTypeLabel.text = device.deviceName
    }
}
