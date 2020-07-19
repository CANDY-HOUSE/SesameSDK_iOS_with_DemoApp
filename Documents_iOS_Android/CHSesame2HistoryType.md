```swift
public enum CHSesame2HistoryType:UInt8
{
    case NONE = 0                 // 何らの原因で紛失した履歴タイプ
    case BLE_LOCK = 1             // コマンドによる施錠
    case BLE_UNLOCK = 2           // コマンドによる解錠
    case TIME_CHANGED = 3         // セサミデバイスの内部時計が校正された
    case AUTOLOCK_UPDATED = 4     // オートロックの設定が変更されました
    case MECH_SETTING_UPDATED = 5 // 施解錠角度の設定が変更されました
    case AUTOLOCK = 6             // セサミデバイスによるオートロック
    case MANUAL_LOCKED = 7  
    case MANUAL_UNLOCKED = 8  
    case MANUAL_ELSE = 9

/*
case MANUAL_LOCKED = 7
手動で施錠 ( ケース2またケース3 から ケース1 になった場合 )

case MANUAL_UNLOCKED = 8
手動で解錠 ( ケース1またケース3 から ケース2 になった場合 )

case MANUAL_ELSE = 9
解錠の点または施錠の点から、サムターンに動きがあった場合（　ケース１からケース３になった場合、またはケース２からケース３になった場合）



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


補足２：現時点のSDKとAPPでは解錠と施錠は「点」となっておりますが、今後ユーザー様が解錠/施錠状態を範囲で設定出来る様に変更予定で、ファームウェアにはその機能は実装しております。
*/

}
```
