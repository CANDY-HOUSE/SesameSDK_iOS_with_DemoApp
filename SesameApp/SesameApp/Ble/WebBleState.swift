import SesameSDK

extension CHDeviceStatus {
    var webBleState: String {
        switch self {
        case .noBleSignal: return "noBleSignal"
        case .receivedBle: return "receivedBle"
        case .bleConnecting: return "bleConnecting"
        case .reset: return "reset"
        case .waitingGatt: return "waitingGatt"
        case .bleLogining: return "bleLogining"
        case .readyToRegister: return "readyToRegister"
        case .waitingForAuth: return "waitingForAuth"
        case .registering: return "registering"
        case .dfumode: return "dfumode"
        case .locked: return "locked"
        case .unlocked: return "unlocked"
        case .moved: return "moved"
        case .noSettings: return "noSettings"
        case .waitApConnect: return "waitApConnect"
        case .busy: return "busy"
        case .iotConnected, .iotDisconnected: return ""
        }
    }
}
