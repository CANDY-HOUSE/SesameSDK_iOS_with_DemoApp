import SesameGateway
import SesameSDK
import SwiftUI
import WatchKit

extension Color {
    static let sesameGreen = Color(red: 0x28 / 255, green: 0xae / 255, blue: 0xb1 / 255)
    static let sesameLightGray = Color(red: 0xcc / 255, green: 0xcc / 255, blue: 0xcc / 255)
    static let lockRed = Color(red: 0xcc / 255, green: 0x4a / 255, blue: 0x44 / 255)
    static let lockGray = Color(red: 0xe4 / 255, green: 0xe3 / 255, blue: 0xe3 / 255)
}

/// Reads the shadow every 2 seconds while the page is shown, as the native Watch app did; only for devices with a gateway.
@MainActor
final class DeviceShadow: ObservableObject {
    @Published private(set) var shadow: SesameGateway.Shadow?
    private var polling: Task<Void, Never>?

    func start(_ item: WatchStore.Device) {
        guard item.gateway, polling == nil, let id = UUID(uuidString: item.id) else { return }
        polling = Task {
            while !Task.isCancelled {
                if (try? WatchGateway.configure()) != nil {
                    shadow = try? await SesameGateway.shadow(deviceId: id)
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func stop() {
        polling?.cancel()
        polling = nil
    }
}

struct DeviceView: View {
    @EnvironmentObject private var devices: WatchDevices
    @StateObject private var shadow = DeviceShadow()
    @State private var busy = false
    let item: WatchStore.Device

    var body: some View {
        let state = LockState(device: devices.device(item.id), kind: item.kind, shadow: shadow.shadow, bleBattery: devices.battery(item.id))
        GeometryReader { geometry in
            VStack {
                HStack {
                    Image(state.bluetoothImage).resizable().frame(width: 12, height: 12)
                    Image(state.gatewayOnline ? "wifi_green" : "wifi_gray").resizable().frame(width: 12, height: 12)
                    Spacer()
                    if let battery = state.battery {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .foregroundColor(battery < 15 ? .lockRed : .sesameGreen)
                                .frame(width: 12 * CGFloat(battery) / 100, height: 6)
                            Image("icn-battery").resizable().frame(width: 15, height: 12)
                        }
                        Text("\(battery)%")
                            .font(.system(size: 10))
                            .foregroundColor(.sesameLightGray)
                    }
                }
                lockButton(state, size: geometry.size.width * 0.7)
                Text(item.name)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: geometry.size.width)
            }
        }
        .onAppear { shadow.start(item) }
        .onDisappear { shadow.stop() }
    }

    private func lockButton(_ state: LockState, size: CGFloat) -> some View {
        ZStack {
            Button(action: { operate(state) }) {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 1)
                    .background(Image(state.image).renderingMode(.original).resizable().aspectRatio(contentMode: .fill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(busy)
            if let degrees = state.degrees {
                let radians = degrees * .pi / 180
                Circle()
                    .fill(state.locked == true ? Color.lockRed : state.locked == false ? Color.sesameGreen : Color.lockGray)
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(x: cos(radians) * size / 2, y: sin(radians) * size / 2)
                    .animation(.default, value: degrees)
            }
        }
        .frame(width: size, height: size)
    }

    /// Tap: lock toggle, Bot click, Bike unlock, as in the native Watch app. Bluetooth first, then the gateway.
    private func operate(_ state: LockState) {
        busy = true
        let operation: SesameOperation = item.kind == .bike ? .unlock : .toggle
        Task {
            var success = false
            if state.bleLoggedIn {
                success = await devices.command(operation, item.id)
            } else if state.gatewayOnline, let key = KeyStore.shared.key(item.id) {
                success = (try? await SesameGateway.send(command: operation.command(item.kind), deviceId: key.deviceUUID,
                                                          secretKey: key.secretKey, history: devices.gatewayHistoryTag())) != nil
            }
            WKInterfaceDevice.current().play(success ? .click : .failure)
            busy = false
        }
    }
}

/// Bluetooth status when logged in, otherwise the shadow when a gateway is online. Battery likewise, falling back to the shadow.
struct LockState {
    let bleLoggedIn: Bool
    let gatewayOnline: Bool
    let locked: Bool?
    /// Angle of the lock indicator; locks only.
    let degrees: Double?
    let battery: Int?
    let image: String
    let bluetoothImage: String

    init(device: CHDevice?, kind: SesameDeviceKind, shadow: SesameGateway.Shadow?, bleBattery: Int?) {
        let status = device?.deviceStatus ?? .noBleSignal()
        bleLoggedIn = status.loginStatus == .logined
        gatewayOnline = shadow?.gatewayOnline == true
        var locked: Bool?
        var degrees: Double?
        if bleLoggedIn, let device, let mech = device.mechStatus {
            locked = mech.isInLockRange
            if device is CHSesame5 {
                degrees = Self.reverseDegree(mech.position)
            } else if device is CHSesame2 {
                degrees = Self.angle2degree(mech.position)
            }
        } else if gatewayOnline, let mech = shadow?.mechStatus, mech.count >= 8 {
            // The shadow always carries the 8-byte OS2 layout: battery, target, position (1/1024 turn), retCode, flags.
            let bytes = [UInt8](mech)
            locked = bytes[7] & 2 != 0
            degrees = Self.angle2degree(Int16(bitPattern: UInt16(bytes[4]) | UInt16(bytes[5]) << 8))
        }
        self.locked = locked
        self.degrees = kind == .lock ? degrees : nil
        battery = (bleLoggedIn ? bleBattery : nil) ?? (gatewayOnline ? shadow?.batteryPercentage : nil)
        let prefix = kind == .bot ? "switch-" : ""
        if let locked {
            image = prefix + (locked ? "locked" : "unlocked")
        } else {
            switch status {
            case .bleConnecting, .receivedBle: image = prefix + "receivedBle"
            case .waitingGatt, .waitingForAuth: image = prefix + "waitingGatt"
            case .bleLogining, .readyToRegister, .registering, .dfumode: image = prefix + "bleLogining"
            case .noSettings: image = "noSettings"
            default: image = prefix + "noBleSignal"
            }
        }
        switch status {
        case .bleConnecting, .waitingGatt, .waitingForAuth, .bleLogining, .readyToRegister, .waitApConnect, .busy:
            bluetoothImage = "bluetooth_yellow"
        case .locked, .unlocked, .moved, .noSettings, .registering, .dfumode:
            bluetoothImage = "bluetooth_green"
        default:
            bluetoothImage = "bluetooth_gray"
        }
    }

    /// Sesame 2/4 report 1/1024 turns; same conversion as the native app.
    private static func angle2degree(_ angle: Int16) -> Double {
        let degree = Double(angle % 1024) * 360 / 1024
        return degree > 0 ? 360 - degree : abs(degree)
    }

    /// Sesame 5 and later report degrees.
    private static func reverseDegree(_ angle: Int16) -> Double {
        let degree = Double(angle % 1024)
        return degree > 0 ? 360 - degree : abs(degree)
    }
}
