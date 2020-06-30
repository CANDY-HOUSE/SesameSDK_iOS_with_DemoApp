//
//  BLEAutoTest.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/9/11.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import SesameSDK
import CoreBluetooth

class BluetoothAutoTestViewController: BaseLightViewController {
    var deviceID: String?
    var sesame: CHSesameBleInterface?
    var logList = [String]()
    @IBOutlet weak var deviceIDLB: UILabel!
    @IBOutlet weak var LogTable: UITableView!
    @IBOutlet weak var logView: UILabel!
    @IBOutlet weak var gattStatusLB: UILabel!
    @IBOutlet weak var registerLB: UILabel!

    var gattStatus: CHBleGattStatus = CHBleGattStatus.idle {
        didSet {
            gattStatusLB.text = gattStatus.description()
            switch gattStatus {
            case .idle:
                stateMachine.process(event: .idle)
            case .connecting:
                stateMachine.process(event: .connecting)
            case .connected:
                stateMachine.process(event: .connected)
            case .established:
                stateMachine.process(event: .established)
            case .busy:
                stateMachine.process(event: .busy)
            case .error:
                stateMachine.process(event: .error)
            case .underDfu:
                stateMachine.process(event: .underDfu)
            }
        }
    }
    enum EventType {
        case idle, connecting, connected, established, busy, error, underDfu//gattstatus
        case registOK, registFail//register
        case lock, unlock, autolock, configureMech, unknown, registration, enableDFU, version, login,user//command
    }
    enum StateType {
        case TestConnectST
        case TestRegistST
        case TestSetLockST
        case TestLock
        case TestUnLock
        case TestAutoLock
        case TestUnRegister
    }
    typealias gattTransition = Transition<StateType, EventType>
    typealias StateMachineDefault = StateMachine<StateType, EventType>

    let stateMachine = StateMachineDefault(initialState: .TestConnectST, callbackQueue: DispatchQueue(label: "com.albertodebortoli.someSerialCallbackQueue"))

    override func viewWillAppear(_ animated: Bool) {
        CHBleManager.shared.enableScan()
    }

    override func viewWillDisappear(_ animated: Bool) {
        CHBleManager.shared.disableScan()
    }
    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .light
        }

        CHBleManager.shared.delegate = self

        self.LogTable.dataSource = self
        stateMachine.enableLogging = true
        stateMachine.logDelegate = self


        let C2C_I = gattTransition(with: .idle,
                                   from: .TestConnectST,
                                   to: .TestConnectST,
                                   postBlock: {
                                    do {
                                        try self.sesame!.connect()
                                    } catch {
                                        self.logView.text =  "\(error)"
                                    }

        })
        let C2C = gattTransition(with: .busy,
                                 from: .TestConnectST,
                                 to: .TestConnectST,
                                 preBlock: {
                                    sleep(UInt32(5))
        },
                                 postBlock: {
                                    do {
                                        try self.sesame!.connect()
                                    } catch {
                                        self.logView.text =  "\(error)"
                                    }

        })

        let C2R = gattTransition(with: .established,
                                 from: .TestConnectST,
                                 to: .TestRegistST,
                                 postBlock: {
                                    do {
                                        try self.sesame!.register(nickname: "testApp", {(result) in
                                            if result.success {
                                                CHAccountManager.shared.deviceManager.flushDevices({ (_, result, _) in
                                                    if result.success == true {
                                                        print("register  OK")
                                                        self.stateMachine.process(event: .registOK)

                                                    }
                                                })
                                            } else {
                                                self.stateMachine.process(event: .registFail)
                                            }
                                        })
                                    } catch {
                                        self.stateMachine.process(event: .registFail)
                                        DispatchQueue.main.async {
                                            print(error.localizedDescription)
                                            self.logView.text =  "\(error.localizedDescription)"
                                        }                                    }
        })

        let R2S = gattTransition(with: .registOK, from: .TestRegistST, to: .TestSetLockST,
                                 postBlock: {

                                    do {
                                        try self.sesame!.configureLockPosition(configure: CHSesameLockPositionConfiguration(lockTarget: 1000, unlockTarget: 500))
                                    } catch {
//                                        print("configureLockPosition",error)
                                        self.logView.text =  "\(error)"
                                    }
        })

        let S2L = gattTransition(with: .configureMech, from: .TestSetLockST, to: .TestLock,
                                 preBlock: {
                                    do {try self.sesame!.lock()} catch {
                                        //                                        print(error)
                                        self.logView.text =  "\(error)"
                                    }        },
                                 postBlock: {
                                    sleep(UInt32(4))
        })

        let L2UL = gattTransition(with: .lock, from: .TestLock, to: .TestUnLock,
                                  preBlock: {
                                    do {
                                        try self.sesame!.unlock()
                                    } catch {
                                        print(error)
                                        self.logView.text =  "\(error)"
                                    }
        },
                                  postBlock: {
                                    sleep(UInt32(4))
        })


        let L2AutoL = gattTransition(with: .unlock, from: .TestUnLock, to: .TestAutoLock,
                                     preBlock: {},
                                  postBlock: {
                                    sleep(UInt32(5))
                                    do {
                                        try self.sesame!.enableAutolock(delay: 2)
                                    } catch {
                                        print(error)
                                        self.logView.text =  "\(error)"
                                    }
        })

        let UL2UR = gattTransition(with: .autolock, from: .TestAutoLock, to: .TestUnRegister,
                                   postBlock: {
                                    sleep(UInt32(5))
                                    do {
                                        guard let sesame = self.sesame,
                                            let bleId = sesame.bleId else {
                                                print("Incomplete data, ignore unregister")
                                                return
                                        }
                                        try sesame.unregister()
                                        let deviceProfile = CHAccountManager.shared.deviceManager.getDeviceBy(bleId, sesame.model)

                                        if let deviceProfile = sesame.deviceProfile {
                                                   deviceProfile.unregisterDeivce() { (result) in
                                                       CHLogger.debug("unregister result:\(result.success), \(result.errorDescription ?? "unknown")")
                                                       print("flushDevices~")
                                                       ViewHelper.showAlertMessage(title: "Unregister Server", message: "success", actionTitle: "ok", viewController: self)
                                                       if result.success {
                                                           DispatchQueue.main.async {
                                                                                                                   self.logView.text = "test OK"
                                                                                                               }
                                                                                                               CHAccountManager.shared.deviceManager.flushDevices({ (_, result, _) in
                                                                                                                   if result.success == true {
                                                                                                                       sleep(2)
                                                                                                                       print("flushDevices ok")
                                                           //                                                            DispatchQueue.main.async {
                                                           //                                                            self.navigationController?.popViewController(animated: true)
                                                           //                                                            }
                                                                                                                   }
                                                                                                               })
                                                       }
                                                   }
                                               }
//                                        if let deviceProfile = deviceProfile {
//                                            deviceProfile.unregisterDeivce(deviceId: deviceProfile.deviceId, model: deviceProfile.model) { (result) in
//                                                CHLogger.debug("unregister result:\(result.success), \(result.errorDescription ?? "unknown")")
//                                                print("unregister result:\(result.success), \(result.errorDescription ?? "unknown")")
//                                                print("flushDevices~")
//
//                                                if result.success {
//
//                                                    DispatchQueue.main.async {
//                                                        self.logView.text = "test OK"
//                                                    }
//                                                    CHAccountManager.shared.deviceManager.flushDevices({ (_, result, _) in
//                                                        if result.success == true {
//                                                            sleep(2)
//                                                            print("flushDevices ok")
////                                                            DispatchQueue.main.async {
////                                                            self.navigationController?.popViewController(animated: true)
////                                                            }
//                                                        }
//                                                    })
//                                                }
//                                            }
//                                        }
                                    } catch {
                                        print(error)
                                        DispatchQueue.main.async {
                                        self.logView.text =  "\(error)"
                                        }
                                    }
        })


        stateMachine.add(transition: C2C_I)
        stateMachine.add(transition: C2C)
        stateMachine.add(transition: C2R)
        stateMachine.add(transition: R2S)
        stateMachine.add(transition: S2L)
        stateMachine.add(transition: L2UL)
        stateMachine.add(transition: L2AutoL)
        stateMachine.add(transition: UL2UR)

        if let sesame = CHBleManager.shared.getSesame(identifier: deviceID!) {
            sesame.delegate = self
            self.sesame = sesame
            deviceIDLB.text = "deviceBleId:\(sesame.bleId?.toHexString().prefix(8) ?? "")"
            gattStatus = sesame.gattStatus
        }
    }
}
extension BluetoothAutoTestViewController: CHSesameBleDeviceDelegate {
    func onMechSettingChanged(device: CHSesameBleInterface, setting: CHSesameMechSettings) {
    }

    func onMechStatusChanged(device: CHSesameBleInterface, status: CHSesameMechStatus, intention: CHSesameIntention) {
    }

    func onSesameLogin(device: CHSesameBleInterface, setting: CHSesameMechSettings, status: CHSesameMechStatus) {
    }

    func onBleConnectStatusChanged(device: CHSesameBleInterface, status: CBPeripheralState) {
    }

    func onBleGattStatusChanged(device: CHSesameBleInterface, status: CHBleGattStatus, error: CHSesameGattError?) {
        DispatchQueue.main.async {
            self.gattStatus = status
        }
    }

    func onBleCommandResult(device: CHSesameBleInterface, command: CHSesameCommand, returnCode: CHSesameCommandResult) {



        if(returnCode ==  .success) {
            L.d(command.description())

            switch command {
            case .lock:
                stateMachine.process(event: .lock)
            case .unlock:
                stateMachine.process(event: .unlock)
            case .autolock:
                stateMachine.process(event: .autolock)
            case .configureMech:
                stateMachine.process(event: .configureMech)
            case .unknown:
                stateMachine.process(event: .unknown)
            case .registration:
                stateMachine.process(event: .registration)
            case .enableDFU:
                stateMachine.process(event: .enableDFU)
            case .version:
                stateMachine.process(event: .version)
            case .login:
                print("login  !!!")
                stateMachine.process(event: .login)
            case .user:
                                stateMachine.process(event: .user)

            }
        }

    }
}

extension BluetoothAutoTestViewController: CHBleManagerDelegate {
    func didDiscoverSesame(device: CHSesameBleInterface) {
             let   isRegisted = self.sesame!.isRegistered
        registerLB.text = "\(isRegisted ? "Registered" : "UnRegistered!")"
    }
}
extension BluetoothAutoTestViewController: StateMLogDelegete {
    func log(msg: String) {
        logList.append(msg)
        DispatchQueue.main.async {
            self.logView.text = msg
            self.LogTable.reloadData()
        }
    }
}

extension BluetoothAutoTestViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.logList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = LogTable.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }

        cell?.textLabel?.text = self.logList[indexPath.row]
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 14.0)
        return cell!
    }
}
