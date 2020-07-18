# CHSesameStatus
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
## if unregistered


| action/status | noSignal  | receiveBle  | connecting    | readytoRegister | nosetting  |
|:-------------:|:---------:|:-----------:|:-------------:|:---------------:|:----------:|
|  close to ssm |receiveBle |             |               |                 |            |
|  connect      |           | connecting  |               |                 |            |
|  connecting   |           |             |readytoRegister|                 |            |
|  register     |           |             |               | nosetting       |            |
|  configureLockPosition    |    |        |               |         | locked/unlocked(registered)|
|  disconnect   |           |             |            |    noSignal     | noSignal   |

## if registered
| action/status | noSignal  | receiveBle  | connecting  | waitgatt | logining | locked/unlocked  |nosetting  |
|:-------------:|:---------:|:-----------:|:-----------:|:--------:|:---------------:|:----------:|:----------:|
|  close to ssm |receiveBle |             |             |          |                 |            |            |
|  connect      |           | connecting  |             |          |                 |            |            |
|  connecting   |           |             | waitgatt    |          |                 |            |            |
|  waitgatt     |           |             |             | logining |                 |            |            |
|  logining     |           |             |             |         | locked/unlocked/nosetting |    |            |           
|  lock         |           |             |             |         |                 | unlocked         |   |
|  unlock       |           |             |           |        |                 | locked         |  |
|  toggle       |           |             |           |        |                 | unlocked/locked   |  |
|  disconnect   |            |            |           |          | noSignal   |noSignal   |noSignal   |
