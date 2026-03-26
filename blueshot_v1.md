# Project: Greenshot-Native for Apple Silicon

# Role
macOSアプリ開発のエキスパート。Swift 6 / SwiftUI / ScreenCaptureKitに精通。

# Core Requirements
1. **Security & Permissions (Critical)**:
   - 起動時に「画面収録」の権限チェックを行い、未許可ならシステム設定を開く誘導を行うこと。
   - ユーザー指定フォルダへの継続的な書き込みのため、Security-Scoped Bookmarksを適切に扱うこと。
2. **Flexible Workflow**:
   - 独自のショートカット登録機能。
   - 出力先（クリップボード/フォルダ/両方）の切り替え。
   - 命名規則（${YYYY}${MM}${DD}_${hh}${mm}${ss}等）の変数置換ロジック。
3. **M-Chip Optimization**:
   - Rosetta 2非依存。ScreenCaptureKitによる低負荷・高解像度キャプチャ。
   - マルチディスプレイ環境への完全対応。

# Non-Functional Constraints
- アプリは Sandbox を有効にすること。
- メモリリークを防ぐため、キャプチャ後のイメージバッファを速やかに解放すること。
- UIはSwiftUIでモダンに、設定画面はmacOS標準のスタイル（Settingsプロトコル）に従うこと。

# First Task
まず、アプリの骨格となる「メニューバー常駐部分（MenuBarExtra）」と、
「画面収録権限があるか確認し、なければユーザーに警告する権限チェックマネージャー」のクラスを作成してください。
