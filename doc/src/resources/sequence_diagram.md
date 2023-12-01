@startuml
autonumber

actor "User" as User
participant "Sesame App" as App
participant "BLE Device" as BLE #lightgray

== Preparation ==
activate App
alt BLE status == ON
App -> App: Scan for Bluetooth devices
App -> BLE: Connect
activate BLE
App -> App: Discover services
App -> App: Discover characteristics
App -> BLE: Enable notifications
BLE --> App: Initialization successful and a random code has been returned

deactivate BLE

App -> App: Save random code (session token)
App -> App: Generate key pair A

else BLE status != ON
App -> App: Remind the user to turn on Bluetooth
end 

== Registration ==
User -> App: Add device 

group Sesame5/Bike2/Open Sensor/Sesame Touch
App -> App: Generate command data using public key of key pair A + timestamp
App -> BLE: Send command data
activate BLE
BLE -> BLE: Synchronize time
BLE -> BLE: Generate key pair B
BLE -> BLE: Generate key with public key of key pair A and private key of key pair B
BLE --> App: Return status, settings, public key of key pair B
deactivate BLE
end

group WifiModule2
App -> App: Generate command data using public key of key pair A
App -> BLE: Send command data
activate BLE
BLE -> BLE: Generate key pair B
BLE -> BLE: Generate key with public key of key pair A and private key of key pair B
BLE --> App: Return public key of key pair B
deactivate BLE

App -> App: Scan WiFi, set password, connect WiFi
end
deactivate BLE
App -> App: Generate key with private key of key pair A and public key of key pair B
App -> App: Update command encoder/decoder
App -> App: Persist device information with key
App -> App: Restore device state from shadow
App -> User
deactivate App

== Login ==
group Sesame5/Bike2/Open Sensor/Sesame Touch
App -> App: Generate session authorization with signature
activate App
App -> App: Without signature, generate session authorization with session token and key
App -> App: Update command encoder/decoder
App -> BLE: Send command data
activate BLE
BLE -> BLE: Verify key consistency
BLE --> App: Return timestamp
deactivate BLE

alt ABS(device timestamp - App timestamp) >= 3
App -> App: Get current time
App -> BLE: Send command data
activate BLE
BLE -> BLE: Synchronize time from App
else
end
end
group WifiModule2
App -> App: Update command encoder/decoder
App -> App: Generate command data with key and session token
App -> BLE: Send command data
end
BLE --> App: Response successful
BLE --> App: Publish device status
deactivate BLE
App -> App: Respond with device status
deactivate App

=== Send command ===
User -> App: Tap Sesame
activate App

group lock

group Sesame5/Bike2/Open Sensor/Sesame Touch
alt BLE connected
App -> App: Generate command data
App -> BLE: Send command data
activate BLE
BLE --> App: Publish device status
deactivate BLE
App -> App: Restore interface from device status
end
end

group WifiModule2
App -> App: Generate command data (key and public key when needed)
App -> BLE: Send command data
activate BLE
BLE --> App: Publish device status
deactivate BLE
App -> App: Restore interface from device status
end
App -> User

deactivate App
@enduml
