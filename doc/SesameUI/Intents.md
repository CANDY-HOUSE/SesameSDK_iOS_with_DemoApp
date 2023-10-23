# Intents

使用 iOS Intenes 框架，實現 Siri / 捷徑開關鎖功能。
App 中有三個 Custom Intents: `Toggle Sesame`/`Lock Sesame`/`Unlock Sesame`
`CHExtensionListener`(詳見 AppDelegate) 在 Siri 或 SHort cut 功能切換活躍/非活躍狀態時觸發 對應的 Intent handler

<p>
 <img src="../src/imgs/intent_setting.png" alt="" title="">
</p>

## Lock/Unlock SesameIntent

```Swift
//1.
func handle(intent: UnlockSesameIntent, completion: @escaping (UnlockSesameIntentResponse) -> Void){
    //處理傳入的Intents，開啟藍芽掃描裝置，判斷該裝置為藍芽連線或影子登入情況執行動作。執行動作超過10秒未完成則返回`.failure`結果
}

//2.
func resolveName(for intent: UnlockSesameIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
    // 解析 Intent 中的 SesameLock 名稱，若有找到設備列表中對應名稱(不區分大小寫)的設備就對該設備執行動作
}

//3.Lock || Unlock || Toggle Sesame
func unlock/ lock/ toggle CHDevice(_ device: CHSesameLock, completion: @escaping (UnlockSesameIntentResponse) -> Void){
    //判斷裝置執行開關鎖動作，並在完成時關閉藍芽掃描、藍芽斷連所有裝置。Sesame bike/bike2只支援開鎖，Sesame bot 只支援 .click()
}

```
