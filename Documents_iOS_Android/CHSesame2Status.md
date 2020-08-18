# State Machine
<p align="center" >
  <a href="https://docs.google.com/drawings/d/1a7vZAM9WuwPWO6OKUwSEO41QpbavJ21Ey1W6o_kQHq8/edit?usp=sharing" target="_blank"><img src="https://raw.github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/assets/CHSesame2StateMachine.png" alt="Sesame2 State Machine" title="Sesame2 State Machine"></a>
</p>

# CHSesame2Status
```Swift
noSignal         //SesameSDKがセサミデバイスのBluetooth advertisementを未だ見つけていない
receivedBle      //SesameSDKがセサミデバイスのBluetooth advertisementを見つけました
connecting       //SesameSDKがセサミデバイスとBluetooth接続しようとしている
waitingGatt      //SesameSDKがセサミデバイスとBluetooth接続しようとしている途中、Bluetooth GATTの応答を待っています
readytoRegister  //SesameSDKがセサミデバイスとBluetooth接続出来て、セサミデバイスが未登録状態で、registerSesame2()待ちです
registering      //SesameSDKがセサミデバイスとBluetooth接続出来て、registerSesame2()処理中です
logining         //SesameSDKがセサミデバイスとBluetooth接続出来て、セサミデバイスも登録済で、セサミデバイスの鍵を挿入している途中
nosetting        //SesameSDKがセサミデバイスとBluetooth接続出来て、セサミデバイスも登録済で、正しいセサミデバイスの鍵も挿入済で、セサミデバイスの施解錠の角度は未だ未設定です
locked           //下記のケース１。SesameSDKがセサミデバイスとBluetooth接続出来て、セサミデバイスも登録済で、正しいセサミデバイスの鍵も挿入済。
unlocked         //下記のケース2。SesameSDKがセサミデバイスとBluetooth接続出来て、セサミデバイスも登録済で、正しいセサミデバイスの鍵も挿入済。
moved            //下記のケース3。SesameSDKがセサミデバイスとBluetooth接続出来て、セサミデバイスも登録済で、正しいセサミデバイスの鍵も挿入済。
reset            //セサミデバイスがBluetoothコマンドによりリセットされました
```
```Swift
/*
補足１：現時点では状態は以下の３つのみとなっています。
  ＜ケース１：施錠＞
    サムターンが施錠の点にある場合、
    施錠　1
    解錠　0　
  ＜ケース２：解錠＞
    サムターンが解錠の点にある場合、
    施錠　0
    解錠　1
  ＜ケース３：それ以外（※現時点では「解錠」とUI上で表示しています。 ＞
    サムターンが以上の２点以外にある場合、
    施錠　0
    解錠　0


補足２：現時点のSDKとAPPでは解錠と施錠は「点」となっておりますが、今後ユーザー様が解錠/施錠状態を範囲で設定出来る様に変更予定で、ファームウェアには既にその機能は実装しております。
*/
```

## if(!isRegistered) セサミデバイスが未登録の場合
| 横はstatus<br>縦はアクション | noSignal  | receivedBle  | connecting    |waitingGatt| readytoRegister|registering | nosetting  |
|:-------------:|:---------:|:-----------:|:-------------:|:---------:|:---------------:|:----------:|:----------:|
|セサミデバイスが近くにあれば|receivedBle|       |               |           |                 |            |            |
|  connect()    |           | connecting  |               |           |                 |            |            |
|  connecting   |           |             |  waitingGatt  |           |                 |            |            |
|  waitingGatt  |           |             |               |readytoRegister|             |            |            |
|  registerSesame2()|       |             |               |           | registering     |            |            |
|  registering  |           |             |               |           |                 | nosetting  |            |
|  configureLockPosition()| |             |               |           |                 |            |locked/unlocked/moved<br>(registered)|
|  disconnect() |           |             |               |           |                 |            |  noSignal  |

## if(isRegistered) セサミデバイスが登録済の場合
| 横はstatus<br>縦はアクション | noSignal  | receivedBle | connecting  |waitingGatt|   logining     |locked/unlocked/moved|nosetting|
|:-------------:|:---------:|:-----------:|:-----------:|:--------:|:---------------:|:----------:|:----------:|
|セサミデバイスが近くにあれば|receivedBle |      |             |          |                 |            |            |
|  connect()    |           | connecting  |             |          |                 |            |            |
|  connecting   |           |             | waitingGatt |          |                 |            |            |
|  waitingGatt  |           |             |             | logining |                 |            |            |
|  logining     |           |             |             |          |locked/unlocked/moved/<br>nosetting||      |           
|  lock()       |           |             |             |          |                 | unlocked   |            |
|  unlock()     |           |             |             |          |                 | locked     |            |
|  toggle()     |           |             |             |          |                 |locked/unlocked|         |
|  disconnect() |           |             |             |          | noSignal        |noSignal    |noSignal    |
