


# CHSesame2Status
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
## If unregistered


| action/status | noSignal  | receiveBle  | connecting    | readytoRegister | nosetting  |
|:-------------:|:---------:|:-----------:|:-------------:|:---------------:|:----------:|
|  close to Sesame2 |receiveBle |             |               |                 |            |
|  connect      |           | connecting  |               |                 |            |
|  connecting   |           |             |readytoRegister|                 |            |
|  register     |           |             |               | nosetting       |            |
|  configureLockPosition    |    |        |               |                 | locked/unlocked(registered)|
|  disconnect   |           |             |            |    noSignal     | noSignal   |

## If registered
| action/status | noSignal  | receiveBle  | connecting  | waitgatt | logining | locked/unlocked  |nosetting  |
|:-------------:|:---------:|:-----------:|:-----------:|:--------:|:---------------:|:----------:|:----------:|
|  close to Sesame2 |receiveBle |             |             |          |                 |            |            |
|  connect      |           | connecting  |             |          |                 |            |            |
|  connecting   |           |             | waitgatt    |          |                 |            |            |
|  waitgatt     |           |             |             | logining |                 |            |            |
|  logining     |           |             |             |         | locked/unlocked/nosetting |   |            |           
|  lock         |           |             |             |         |                 | unlocked         |  |
|  unlock       |           |             |           |        |                 | locked         |  |
|  toggle       |           |             |           |        |                 | unlocked/locked   |  |
|  disconnect   |            |            |           |          | noSignal   |noSignal   |noSignal   |
