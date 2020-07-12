
# CHResult pattern
1. [https://developer.apple.com/documentation/swift/result](https://developer.apple.com/documentation/swift/result)
2. typealias CHResult<T> = (Result<CHResultState<T>, Error >) ->  ()

## CHResultState
1. CHResultStateCache: Values from coredata(iOS database)
2. CHResultStateNetworks: Values from networks
3. CHResultStateBLE: Values from BLE
4. [todo] CHResultStateIoT: Values from WiFi Access Point

## NSError table

| Timing/error   |  domain | code       |Message       |
|:---------------------:|:-------------------:|:-----------:|:-----------:|
|  No network                |  SesameSDK     |   -1009       |The Internet connection appears to be offline. | 
|  No API key                |  SesameSDK     |    403        | Forbidden | 
|  Wrong parameter           |  SesameSDK     |    400        | Bad request | 
|  Wrong URL                 |  SesameSDK     |    404        | Not found | 
|  CANDY HOUSE server down   |  SesameSDK     |    502        | Unknown error| 
|  History authentication failed|  SesameSDK     |    401     | History authentication failed| 
|  PARSE_ERROR               |  SesameSDK     |    480        | Data parse failed | 
|  History tag too long       |  SesameSDK     |    600       | Over 22-byte limit | 
|  cmd connect/lock          | CBCentralManager   |  4        | PoweredOff| 
|  cmd connect/lock          | CBCentralManager   |  3        | Unauthorized| 
|  cmd connect/lock          | CBCentralManager   |  2        | Unsupported| 
|  cmd connect/lock          |  SesameSDK     |   -2          | No BLE signal| 
|  cmd lock                  |  SesameSDK     |   -1          | unlogin|
|    cmd lock                |  SesameSDK      |   1          | Invalid Format| 
|    cmd lock                |  SesameSDK      |   2          | notSupported| 
|    cmd lock                |  SesameSDK      |   3          | resultStorageFail| 
|    cmd lock                |  SesameSDK      |   4          | invalidSig| 
|    cmd lock                |  SesameSDK      |   5          | notFound| 
|    cmd lock                |  SesameSDK      |   6          | unknown| 
|    cmd lock                |  SesameSDK      |   7          | busy| 
|    cmd lock                |  SesameSDK      |   8          | invalidFormat| 


[List of HTTP status codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes) (For reference)

# example
```swift
       ssm.toggle { result in
                switch result {
                case .success(let chResultState):
                    L.d("CHResultState" , chResultState,chResultState.data)
                    //["CHResultState", SesameSDK.CHResultStateBLE<SesameSDK.CHEmpty>, SesameSDK.CHEmpty]
                case .failure(let error):
                    L.d("error",error)
                }
        }
```
