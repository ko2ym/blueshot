# Blueshot 要件一覧

## 背景・目的

Greenshotというスクリーンショットツール（Windows/macOS対応）のmacOS Apple Silicon向け後継アプリを作成する。
Greenshotはバージョンアップが停止しており、Intel Macでしか動作しない。Apple Silicon (M1/M2/M3/M4チップ) ネイティブ対応が必要。

---

## 1. キャプチャ機能要件


| ID     | 要件                             | 優先度    |
| ------ | ------------------------------ | ------ |
| CAP-01 | 領域選択キャプチャ（ドラッグで矩形範囲を指定）        | Must   |
| CAP-02 | アクティブウィンドウキャプチャ                | Must   |
| CAP-03 | 全画面キャプチャ（ディスプレイ指定対応）           | Must   |
| CAP-04 | 前回同領域の再キャプチャ                   | Should |
| CAP-05 | 撮影タイマー（遅延撮影：1〜10秒）             | Should |
| CAP-06 | マウスポインタのキャプチャへの含有/除外           | Should |
| CAP-07 | マルチディスプレイ完全対応（全ディスプレイ同時含む）     | Must   |
| CAP-08 | Retina/HiDPI解像度でのキャプチャ（物理ピクセル） | Must   |
| CAP-09 | ウィンドウ選択キャプチャ（クリックしたウィンドウ）      | Should |
| CAP-10 | スクロールキャプチャ                     | Could  |
| CAP-11 | キャプチャ後のフローティングプレビュー（左下に数秒表示）   | Should |


## 2. 画像編集機能要件


| ID     | 要件                     | 優先度    |
| ------ | ---------------------- | ------ |
| EDT-01 | 矩形描画（塗りつぶし・枠線、色・太さ指定）  | Must   |
| EDT-02 | 楕円描画                   | Should |
| EDT-03 | 直線・矢印描画                | Must   |
| EDT-04 | フリーハンド描画               | Could  |
| EDT-05 | テキスト追加（フォント・サイズ・色指定）   | Must   |
| EDT-06 | ハイライト（半透明マーキング）        | Must   |
| EDT-07 | ぼかし（ガウシアンブラー、強度調整）     | Must   |
| EDT-08 | ピクセル化/モザイク（難読化）        | Must   |
| EDT-09 | トリミング                  | Should |
| EDT-10 | ステップ番号付き吹き出し（番号+円形バッジ） | Should |
| EDT-11 | Undo/Redo（複数ステップ対応）    | Must   |


## 3. 出力・エクスポート要件


| ID     | 要件                                      | 優先度    |
| ------ | --------------------------------------- | ------ |
| EXP-01 | ファイル保存（PNG形式）                           | Must   |
| EXP-02 | ファイル保存（JPEG、品質設定可）                      | Must   |
| EXP-03 | クリップボードへのコピー                            | Must   |
| EXP-04 | 保存先フォルダ指定（Security-Scoped Bookmarks）    | Must   |
| EXP-05 | ファイル命名規則の変数置換（${YYYY}/${MM}/${DD}等）     | Must   |
| EXP-06 | 連番付きファイル名（${index}変数）                   | Should |
| EXP-07 | macOS標準共有シート連携（AirDrop/メモ/Slack等を一括カバー） | Should |
| EXP-08 | ドラッグ&ドロップで外部アプリへ転送                      | Should |
| EXP-09 | 保存完了の通知センター通知                           | Should |
| EXP-10 | メール添付（macOS Mail連携）                     | Could  |
| EXP-11 | 印刷（macOS標準印刷ダイアログ）                      | Could  |


## 4. UI/UX要件


| ID    | 要件                                 | 優先度    |
| ----- | ---------------------------------- | ------ |
| UI-01 | メニューバー常駐（MenuBarExtra、Dockアイコン非表示） | Must   |
| UI-02 | 設定画面（macOS標準Settingsプロトコル、タブ式）     | Must   |
| UI-03 | 領域選択UI（クロスヘア＋倍率ルーペ付き）              | Must   |
| UI-04 | 起動時の権限誘導UI（System Settings直接リンク）   | Must   |
| UI-05 | ライト/ダークモード自動対応                     | Must   |
| UI-06 | 領域選択時のウィンドウ境界自動スナップ（AXUIElement）   | Should |
| UI-07 | 領域選択時のサイズ・座標リアルタイム表示               | Should |
| UI-08 | キャプチャ後の編集ウィンドウ自動表示（設定でスキップ可）       | Should |
| UI-09 | ログイン時自動起動設定（SMAppService）          | Should |
| UI-10 | 初回起動時のオンボーディング（権限取得フロー）            | Should |
| UI-11 | 日本語・英語ローカライズ                       | Should |


## 5. ショートカット・ホットキー要件


| ID     | 要件                                    | 優先度    |
| ------ | ------------------------------------- | ------ |
| HOT-01 | グローバルホットキー登録（アプリ非アクティブ時も有効）           | Must   |
| HOT-02 | 領域選択キャプチャのホットキー                       | Must   |
| HOT-03 | アクティブウィンドウキャプチャのホットキー                 | Must   |
| HOT-04 | 全画面キャプチャのホットキー                        | Must   |
| HOT-05 | ホットキーのカスタマイズ（設定画面で変更可）                | Must   |
| HOT-06 | ホットキーの競合検出・警告                         | Should |
| HOT-07 | 前回同領域キャプチャのホットキー                      | Should |
| HOT-08 | macOS標準ショートカット（Cmd+Shift+3/4/5）との競合回避 | Must   |


## 6. 設定・カスタマイズ要件


| ID     | 要件                       | 優先度    |
| ------ | ------------------------ | ------ |
| CFG-01 | 出力先（クリップボード/フォルダ/両方）の選択  | Must   |
| CFG-02 | デフォルト保存フォルダの指定           | Must   |
| CFG-03 | ファイル命名規則設定（変数プレビュー付き）    | Must   |
| CFG-04 | デフォルト出力形式選択（PNG/JPEG）    | Must   |
| CFG-05 | JPEG品質設定（スライダー）          | Should |
| CFG-06 | シャッター音のON/OFF            | Should |
| CFG-07 | マウスポインタ含有設定              | Should |
| CFG-08 | 撮影遅延のデフォルト秒数             | Should |
| CFG-09 | キャプチャ後の編集ウィンドウ表示設定       | Should |
| CFG-10 | Retina出力解像度選択（@1x / @2x） | Should |
| CFG-11 | 設定のエクスポート/インポート（JSON形式）  | Could  |


## 7. セキュリティ・権限要件


| ID     | 要件                                      | 優先度    |
| ------ | --------------------------------------- | ------ |
| SEC-01 | App Sandbox の有効化                        | Must   |
| SEC-02 | 画面収録権限の起動時チェック                          | Must   |
| SEC-03 | 未許可時のシステム設定誘導                           | Must   |
| SEC-04 | Security-Scoped Bookmarks によるフォルダアクセス   | Must   |
| SEC-05 | キャプチャバッファの速やかなメモリ解放                     | Must   |
| SEC-06 | ユーザーデータのローカル完結（明示的操作のみクラウド送信）           | Must   |
| SEC-07 | 権限取得後の自動リトライ処理                          | Should |
| SEC-08 | アクセシビリティ権限（ウィンドウスナップ使用時）                | Should |
| SEC-09 | Hardened Runtime + Apple Notarization対応 | Should |


## 8. 技術要件・非機能要件


| ID     | 要件                                         | 優先度    |
| ------ | ------------------------------------------ | ------ |
| TEC-01 | Apple Silicon（arm64）ネイティブビルド（Rosetta 2不使用） | Must   |
| TEC-02 | 最小サポートOS: macOS 13 Ventura以上               | Must   |
| TEC-03 | ScreenCaptureKit によるキャプチャ実装                | Must   |
| TEC-04 | Swift 6 対応（Strict Concurrency準拠）           | Must   |
| TEC-05 | SwiftUI + AppKit ハイブリッドアーキテクチャ             | Must   |
| TEC-06 | キャプチャから保存完了までのレイテンシ: 500ms以内               | Should |
| TEC-07 | 依存ライブラリは最小限（基本はApple Frameworksのみ）         | Should |
| TEC-08 | ユニットテスト（命名規則変数置換等の純粋ロジック）                  | Should |
| TEC-09 | Universal Binary（Intel Mac互換）対応            | Could  |


---

## フェーズ分け（開発優先順位）

### Phase 1（MVP）

メニューバー常駐 → 領域/ウィンドウ/全画面キャプチャ
→ 基本編集（矩形/矢印/テキスト/ぼかし/Undo-Redo）
→ PNG/JPEG保存 + クリップボード
→ ホットキー登録
→ セキュリティ・権限管理

対象ID: CAP-01〜03, CAP-07, CAP-08 / EDT-01, EDT-03, EDT-05〜08, EDT-11 / EXP-01〜05 / UI-01〜05 / HOT-01〜05, HOT-08 / CFG-01〜04 / SEC-01〜06 / TEC-01〜05

### Phase 2（v1.1）

- フローティングプレビュー（CAP-11）
- ウィンドウ選択・スナップ（CAP-09, UI-06）
- macOS共有シート / ドラッグ&ドロップ（EXP-07, EXP-08）
- タイマー / 前回同領域キャプチャ（CAP-04, CAP-05）
- ステップ番号バッジ（EDT-10）
- Retina解像度選択（CFG-10）
- オンボーディング / 自動起動（UI-09, UI-10）
- Apple Notarization（SEC-09）

### Phase 3（v1.x+）

- スクロールキャプチャ（CAP-10）
- iCloud Drive保存（EXP-14）
- 設定エクスポート/インポート（CFG-11）
- フリーハンド描画（EDT-04）
- Universal Binary（TEC-09）

---

## Greenshotにない macOSネイティブ差別化機能


| 機能                  | 説明                                            | 使用API/Framework        |
| ------------------- | --------------------------------------------- | ---------------------- |
| フローティングサムネイル        | キャプチャ後に左下に数秒表示されるプレビュー。macOS標準スクリーンショットと同等のUX | SwiftUI overlay        |
| macOS共有シート          | AirDrop/Slack/メモ等をプラグイン不要でカバー                 | NSSharingServicePicker |
| ウィンドウ境界スナップ         | 領域選択時にウィンドウ枠を自動検出してスナップ                       | AXUIElement            |
| SMAppService ログイン項目 | macOS 13以降の正規自動起動API                          | ServiceManagement      |
| Retina解像度選択         | @1x/@2x切り替えで用途に応じた出力                          | ScreenCaptureKit       |


