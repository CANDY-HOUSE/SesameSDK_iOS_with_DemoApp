# CHResult pattern
1. [https://developer.apple.com/documentation/swift/result](https://developer.apple.com/documentation/swift/result)
2. [https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/-result/](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/-result/)
3. typealias CHResult<T> = (Result<CHResultState<T>, Error >) ->  ()

## CHResultState
1. CHResultStateCache: Values from coredata(iOS database / Android Database)
2. CHResultStateNetworks: Values from networks
3. CHResultStateBLE: Values from BLE
4. [todo] CHResultStateIoT: Values from WiFi Access Point

## NSError table
1. [HTTP status codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes)
2. [Apple CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate)

| Timing/error   |  domain | code       |Message       |
|:---------------------:|:-------------------:|:-----------:|:-----------:|
|  No network                |  SesameSDK     |   -1009       |The Internet connection appears to be offline. | 
|  No API key                |  SesameSDK     |    403        | Forbidden | 
|  Wrong parameter           |  SesameSDK     |    400        | Bad request | 
|  Wrong URL                 |  SesameSDK     |    404        | Not found | 
|  CANDY HOUSE server down   |  SesameSDK     |    502        | Unknown error| 
|  History authentication failed|  SesameSDK     |    401     | History authentication failed| 
|  PARSE_ERROR               |  SesameSDK     |    480        | Data parse failed | 
|  History tag too long       |  SesameSDK     |    600       | Over 21-byte limit | 
|  cmd connect/lock/unlock   | CBCentralManager   |  4        | PoweredOff| 
|  cmd connect/lock/unlock   | CBCentralManager   |  3        | Unauthorized| 
|  cmd connect/lock/unlock   | CBCentralManager   |  2        | Unsupported| 
|  cmd connect/lock/unlock   |  SesameSDK     |   -2          | No BLE signal| 
|  cmd lock/unlock           |  SesameSDK     |   -1          | Sesame BLE unlogin|
|    cmd lock/unlock         |  SesameSDK      |   1          | Invalid Format| 
|    cmd lock/unlock         |  SesameSDK      |   2          | notSupported| 
|    cmd lock/unlock         |  SesameSDK      |   3          | resultStorageFail| 
|    cmd lock/unlock         |  SesameSDK      |   4          | invalidSig| 
|    cmd lock/unlock         |  SesameSDK      |   5          | notFound| 
|    cmd lock/unlock         |  SesameSDK      |   6          | unknown| 
|    cmd lock/unlock         |  SesameSDK      |   7          | busy| 
|    cmd lock/unlock         |  SesameSDK      |   8          | invalid Param| 


# example

## IOS
```swift
       sesame2.toggle { result in
                switch result {
                case .success(let chResultState):
                    L.d("CHResultState" , chResultState,chResultState.data)
                    //["CHResultState", SesameSDK.CHResultStateBLE<SesameSDK.CHEmpty>, SesameSDK.CHEmpty]
                case .failure(let error):
                    L.d("error",error)
                }
        }
```
## Android
``` kotlin
      sesame2.toggle() {
          it.onSuccess {

          }
          it.onFailure {
             L.d ("message" + it)
              L.d("code t" + (it as NSError).code)
              L.d("domaon!!!!!:" + (it as NSError).domaon)
              toastMSG(it.message)
          }
      }
```
