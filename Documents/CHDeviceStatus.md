# CHDeviceStatus
```Swift
    noSignal      
    receiveBle
    connecting
    reset
    waitgatt
    logining
    readytoRegister
    locked
    unlocked
    moved
    nosetting
```
## unregistered


| action/status | noSignal  | receiveBle  | connecting    | readytoRegister | nosetting  |
|:-------------:|:---------:|:-----------:|:-------------:|:---------------:|:----------:|
|  close to ssm |receiveBle |             |               |                 |            |
|  connect      |           | connecting  |               |                 |            |
|  connecting   |           |             |readytoRegister|                 |            |
|  register     |           |             |               | nosetting       |            |
|  configureLockPosition    |    |        |               | nosetting       | locked/unlocked(registered)|
|  disconnect   |           |             |            |    noSignal     | noSignal   |

## registered
| action/status | noSignal  | receiveBle  | connecting  | waitgatt | logining | locked/unlocked  |nosetting  |
|:-------------:|:---------:|:-----------:|:-----------:|:--------:|:---------------:|:----------:|:----------:|
|  close to ssm |receiveBle |             |             |          |                 |            |            |
|  connect      |           | connecting  |             |          |                 |            |            |
|  connecting   |           |             | waitgatt    |          |                 |            |            |
|  waitgatt     |           |             |             | logining |                 |            |            |
|  logining     |           |             |             |         | |locked/unlocked/nosetting    |            |           
|  lock         |           |             |             |         |                 | unlocked         |nosetting   |
|  unlock       |           |             |           |        |                 | locked         |nosetting   |
|  toggle       |           |             |           |        |                 | unlocked/locked   |nosetting   |
|  disconnect   |            |            |           |          | noSignal   |noSignal   |noSignal   |
