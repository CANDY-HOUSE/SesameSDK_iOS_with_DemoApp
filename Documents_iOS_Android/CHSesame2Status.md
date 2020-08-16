# State Machine
<p align="center" >
  <a href="https://docs.google.com/drawings/d/1a7vZAM9WuwPWO6OKUwSEO41QpbavJ21Ey1W6o_kQHq8/edit?usp=sharing" target="_blank"><img src="https://raw.github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/assets/CHSesame2StateMachine.png" alt="Sesame2 State Machine" title="Sesame2 State Machine"></a>
</p>

# CHSesame2Status
```Swift
noSignal      
receivedBle
connecting
reset
waitingGatt
logining
readytoRegister
registering
locked
unlocked
moved
nosetting
```

## If unregistered
| action/status | noSignal  | receivedBle  | connecting    |waitingGatt| readytoRegister|registering | nosetting  |
|:-------------:|:---------:|:-----------:|:-------------:|:---------:|:---------------:|:----------:|:----------:|
|close to Sesame2|receivedBle|            |               |           |                 |            |            |
|  connect()    |           | connecting  |               |           |                 |            |            |
|  connecting   |           |             |  waitingGatt  |           |                 |            |            |
|  waitingGatt  |           |             |               |readytoRegister|             |            |            |
|  registerSesame2()|       |             |               |           | registering     |            |            |
|  registering  |           |             |               |           |                 | nosetting  |            |
|  configureLockPosition()| |             |               |           |                 |            |locked/unlocked/moved<br>(registered)|
|  disconnect() |           |             |               |           |                 |            |  noSignal  |

## If registered
| action/status | noSignal  | receivedBle | connecting  |waitingGatt|   logining     |locked/unlocked/moved|nosetting|
|:-------------:|:---------:|:-----------:|:-----------:|:--------:|:---------------:|:----------:|:----------:|
|  close to Sesame2 |receivedBle |        |             |          |                 |            |            |
|  connect()    |           | connecting  |             |          |                 |            |            |
|  connecting   |           |             | waitingGatt |          |                 |            |            |
|  waitingGatt  |           |             |             | logining |                 |            |            |
|  logining     |           |             |             |          |locked/unlocked/moved/<br>nosetting||      |           
|  lock()       |           |             |             |          |                 | unlocked   |            |
|  unlock()     |           |             |             |          |                 | locked     |            |
|  toggle()     |           |             |             |          |                 |locked/unlocked|         |
|  disconnect() |           |             |             |          | noSignal        |noSignal    |noSignal    |
