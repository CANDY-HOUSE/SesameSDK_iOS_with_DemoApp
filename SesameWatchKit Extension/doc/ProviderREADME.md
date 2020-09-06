#  SesameWatchKitUI

## Provider

### Introduction
`Provider` defined a `PassthroughSubject` property named `subjectPublisher` which will emit `ProviderSubject`s.
The concept is use `ProviderSubject` to receive and emit values.

### How to use
1. Initiate an `provider` instance.
2. Subscribe the instance.
3. Call the `connect` to start emit values.

### Example
```swift
private var deviceProvider: ContentProvider
private var disposables = [AnyCancellable]()

deviceProvider
    .subjectPublisher
    .map { $0.result }
    .switchToLatest()
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { complete in
        switch complete {
        case .finished:
            L.d("Finished")
        case .failure(let error):
            L.d("Error: \(error)")
            self.displayText = error.localizedDescription
            self.displayColor = UIColor.white
            self.isShowContent = false
        }
    }) { [weak self] deviceModels in
        guard let strongSelf = self,
            let deviceModels = deviceModels as? [DeviceModel] else {
            return
        }
        L.d("Watch get \(deviceModels.count) device(s).")
        strongSelf.deviceModels = deviceModels.sorted(by: { (left, right) -> Bool in
            left.uuid.uuidString < right.uuid.uuidString
        })
        
        // MARK: - Clear removed device
        let containedSelectedUUID = deviceModels.contains {
            strongSelf.userData.selectedDevice == $0.device.deviceId
        }
        if containedSelectedUUID == false {
            strongSelf.userData.selectedDevice = nil
        }
        strongSelf.displayText = LocalizedString("co.candyhouse.sesame-sdk-test-app.watchkitapp.sesameReady")
        strongSelf.displayColor = UIColor.white
}
.store(in: &disposables)

deviceProvider.connect()
```
## ProviderSubject
### Introduction
`ProviderSubject` defined `request` and `result` `Subject`s.
The concept is use `ProviderSubject` to transfer the value types.

### Hot to use
Initiate an `ProviderSubject` instance and the `ProviderSubject` will emit another type values.

### Example

```swift
let request: CurrentValueSubject<[CHSesame2], Error>
var result: PassthroughSubject = PassthroughSubject<[DeviceModel], Error>()

private var disposables = Set<AnyCancellable>()

init(request: CurrentValueSubject<[CHSesame2], Error>) {
    self.request = request
    self.setup()
}

func connect() {
    let devices = request.value
    request.send(devices)
}

private func setup() {
    request
        .sink(receiveCompletion: { [weak self] subject in
            guard let strongSelf = self else { return }
            switch subject {
            case .finished:
                break
            case .failure(let error):
                strongSelf.result.send(completion: .failure(error))
            }
        }) { [weak self] devices in
            guard let strongSelf = self else { return }
            strongSelf.result.send(
                devices.compactMap { device -> DeviceModel? in
                    guard let uuid = device.deviceId else { return nil }
                    return DeviceModel(uuid: uuid, device: device)
                }
            )
    }
    .store(in: &disposables)
}
```
