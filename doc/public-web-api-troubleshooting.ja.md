# 公開 Web API トラブルシュート（Issue #35 関連）

外部コントリビュータ視点でのメモ。CANDY-HOUSE 公式サポートの代替ではありません。

## 2 種類の API がある

| 種別 | 例 | 認証 | このリポジトリ |
|------|-----|------|----------------|
| **公開 Web API** | `GET https://app.candyhouse.co/api/sesame2/{UUID}` | `X-API-KEY` ヘッダ | **実装なし**（[SesameAPI ドキュメント](https://doc.candyhouse.co/ja/SesameAPI) 参照） |
| **SDK 内部 API** | `GET /prod/device/v1/sesame2/{UUID}` | Cognito（アプリログイン） | `CHAPIClient.getCHDeviceShadow` 等 |

Issue #35 の `{"message": "Internal server error"}` は **公開 Web API 側** の HTTP 500 です。  
iOS SDK の BLE / IoT コードを変更しても、この 500 は直接は直りません。

## Sesame 3 とパス名

製品名が Sesame 3 でも、公開 API のパスは **`/api/sesame2/{UUID}`** のままです（製品名と API 名が一致しないだけ）。

## 500 になる典型パターン（切り分け）

公式ドキュメントおよび SDK の IoT 実装から推測される前提条件:

1. **デバイスオーナー** の API キーを使っている
2. **WiFi Module（旧 WiFi Access Point）** が Sesame とペアリング済み
3. WiFi Module が **Wi-Fi / クラウド（IoT）に接続** している
4. Sesame 公式アプリで **Integration（API 連携）が ON**

上記が満たされないと、サーバーがデバイス shadow を取得できず 500 になることがあります（401/404 ではなく 500 になるケース）。

## 切り分け手順

1. 公式 Sesame アプリで、対象デバイスの **リモート状態表示・解錠** ができるか確認
2. WiFi Module 設定で **Network / IoT** が接続済みか確認
3. 同じ API キー・UUID で `GET /api/sesame2/{UUID}` を再実行
4. 401 → API キー / 権限、404 → UUID 誤り、**500 が継続** → サーバー側調査が必要

## SDK 側で確認できること

- リモート状態は AWS Device Shadow 経由（`CHIoTManager`, `CHDeviceShadow`）で扱われる
- WiFi Module ↔ Sesame の BLE リンク（shadow の `wm2s`）が切れていると、リモート操作が不安定になる（Issue #40 も参照）

## サーバー側調査が必要な場合

500 が前提条件を満たしても継続する場合:

- [Candy House サポート](mailto:sesame@candyhouse.co) へ、**発生時刻・UUID（マスク可）・HTTP ステータス** を添えて問い合わせ
- GitHub Issue: [#35](https://github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/issues/35)
