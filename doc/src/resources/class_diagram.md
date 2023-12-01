@startuml

skinparam linetype ortho
skinparam roundcorner 20
skinparam maxmessageSize 150
skinparam defaultTextAlignment center
skinparam class {
BackgroundColor #EEF
ArrowColor #444
BorderColor #444
}

skinparam shadowing false

class CBCentralManagerDelegate {
	+centralManager:didDiscover:advertisementData:rssi()
	+centralManager:didConnect:()
	+centralManager:didDisconnectPeripheral:error()
	+centralManager:didFailToConnect()
}
class CBPeripheralDelegate {
	+peripheral:didDiscoverServices()
	+peripheral:didDiscoverCharacteristicsFor()
	+peripheral:didUpdateValueForCharacteristic()
	+peripheral:didWriteValueForCharacteristic()
}

class CHBaseDevice {
	+cmdCallBack
	+onResponse
	+onResponseWm2
	+productModel
	+commandQueue
	+gattRxBuffer
	+gattTxBuffer
	+semaphoreSesame
	+isGuestKey
	+sesame2KeyData
	+delegate
	+deviceStatus
	+deviceShadowStatus
	-appKeyPair
	+rssi
	+txPowerLevel
	+isRegistered
	+deviceId
	-characteristic
	+peripheral
	+mechStatus
	+disconnect()
	+connect()
	+dropKey()
	+setAdv()
}

CHBaseDevice .-up-|> CBPeripheralDelegate

class CHSesameOS3 {
	+mSesameToken
	+cipher
	-transmit()
	+sendCommand()
	+peripheral:didDiscoverServices()
	+peripheral:didDiscoverCharacteristicsFor()
	+peripheral:didUpdateValueFor()
	+peripheral:didWriteValueFor()
	-parseNotifyPayload()
}

CHSesameOS3 --up-|> CHBaseDevice

class CHSesameOS3Publish {
	+ onGattSesamePublish()
}

CHSesameOS3 .-up-|> CHSesameOS3Publish

class CHSesame5Device {
	+mechSetting
	+opsSetting
	+isConnectedByWM2
	+isHistory
	+advertisement
	+goIOT()
}

class CHSesame5Device_Command {
	...
}

class CHSesame5Device_Register {
	...
}

class CHSesame5Device_History {
	...
}

CHSesame5Device --up-|> CHSesameOS3
CHSesame5Device *-- CHSesame5Device_Command
CHSesame5Device *-- CHSesame5Device_Register
CHSesame5Device *-- CHSesame5Device_History

class CHDeviceUtil {
	+advertisement()
	+sesame2KeyData()
	+deviceStatus()
	+productModel()
	+goIOT()
	+login()
}

class CHSesame5 {
	+mechSetting
	+opsSetting
	+toggle()
	+getVersionTag()
	+lock()
	+unlock()
	+toggle()
	+getHistories()
	+autolock()
	+configureLockPosition()
	+magnet()
	+opSensorControl()
}

class CHSesameLock {
	+mechStatus
	+getHistoryTag()
	+setHistoryTag:result()
	+enableNotification()
	+disableNotification()
	+isNotificationEnabled()
}

CHSesame5Device ..-up-|> CHDeviceUtil
CHSesame5Device ..-up-|> CHSesame5
CHSesame5 -up-|> CHSesameLock

class CHDevice {
	+delegate
	+rssi
	+deviceId
	+isRegistered
	+txPowerLevel
	+productModel
	+deviceStatus
	+deviceShadowStatus
	+getKey()
	+connect()
	+dropKey()
	+disconnect()
	+getVersionTag()
	+updateFirmware()
	+mechStatus
	+getTimeSignature()
	+reset()
	+register()
	+createGuestKey()
	+getGuestKeys()
	+removeGuestKey()
	+updateGuestKey()
	+getFirZip()
	+checkBle()
}

CHSesameLock -up-|> CHDevice

class CHSesameTouchProDevice {
	-sesame2Keys
	-mechSetting
	-advertisement
	+goIOT()
}

class CHSesameTouchPro_Command {
	...
}

class CHSesameTouchPro_Register {
	...
}

CHSesameTouchProDevice *-- CHSesameTouchPro_Command
CHSesameTouchProDevice *-- CHSesameTouchPro_Register

class CHSesameConnector {
	-sesame2Keys
	-insertSesame()
	-removeSesame()
}

class CHSesameTouchProProtocol {
	-mechSetting
	-getVersionTag()
	-fingerPrints()
	-fingerPrintDelete()
	-fingerPrintsChange()
	-fingerPrintModeGet()
	-fingerPrintModeSet()
	-cards()
	-cardsDelete()
	-cardsChange()
	-cardsModeGet()
	-cardsModeSet()
	-passCodes()
	-passCodeDelete()
	-passCodeChange()
	-passCodeModeGet()
	-passCodeModeSet()
}

CHSesameTouchProProtocol --|> CHSesameConnector
CHSesameTouchProDevice .-down-.|> CHSesameTouchProProtocol
CHSesameTouchProProtocol --|> CHDevice

class CHSesameBike2Device {
}

class CHSesameBike2 {
	-unlock()
}

CHSesameTouchProDevice --up-|> CHSesameOS3
CHSesameBike2Device --up-|> CHSesameOS3
CHSesameBike2Device ..|> CHSesameBike2
CHSesameBike2Device ..|> CHDeviceUtil
CHSesameBike2 -|> CHSesameLock

class CHWifiModule2Device {
	+login()
	-sesame2Keys
	-cipher
	-deviceIR
	-isConnectedToIoT
	-iotShadowName
	-mechSetting
	-wifiModule2Token
	-advertisement
}

class CHWifiModule2 {
	-mechSetting
	+scanWifiSSID()
	+connectWifi()
	+setWifiSSID()
	+setWifiPassword()
}

CHWifiModule2Device .-up-|> CHDeviceUtil
CHWifiModule2Device ..-up-|> CHWifiModule2
CHWifiModule2Device --up-|> CHBaseDevice

class CHWifiModule2Device_Peripheral {
	...
}

class CHWifiModule2Device_Gatt {
	...
}

class CHWifiModule2Device_Register {
	...
}

CHWifiModule2Device *-- CHWifiModule2Device_Peripheral
CHWifiModule2Device *-- CHWifiModule2Device_Gatt
CHWifiModule2Device *-- CHWifiModule2Device_Register

class CHSesameOS2 {
...
}

CHSesameOS2 --up-|> CHBaseDevice

class CHSesame2Device {
...
}

class CHSesameBotDevice {
...
}

class CHBikeLockDevice {
...
}

CHSesameOS2 --> CHSesame2Device
CHSesameOS2 --> CHSesameBotDevice
CHSesameOS2 --> CHBikeLockDevice

class CHBluetoothCenter #FFD54F{
	+delegate
	+statusDelegate
	+centralManager
	+deviceMap
	-scanEnabled
	-discoverUnregisterTimer
	+scanning
	+init()
	+shared()
	+disableScan()
	+enableScan()
	+disConnectAll()
}

CHBluetoothCenter ..-up-|> CBCentralManagerDelegate
CHBluetoothCenter --> CHBaseDevice

class CHDeviceManager #FFD54F{
	+shared()
	+getCHDevices()
	+receiveCHDeviceKeys()
}

CHDeviceManager --> CHBaseDevice

class AppDelegate #41A2A6{
	...         





}

AppDelegate --right--> CHDeviceManager
AppDelegate --> CHBluetoothCenter


@enduml
