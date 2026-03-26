import Foundation

enum BlueshotError: Error, LocalizedError {
    // MARK: - Permission
    case screenRecordingPermissionDenied
    case accessibilityPermissionDenied

    // MARK: - Capture
    case captureFailedNoDisplays
    case captureFailedNoWindow
    case captureFailedInvalidRegion
    case captureFailed(underlying: Error)

    // MARK: - Export
    case exportNoDestination
    case exportBookmarkStale
    case exportWriteFailed(underlying: Error)
    case exportClipboardFailed

    var errorDescription: String? {
        switch self {
        case .screenRecordingPermissionDenied:
            return "画面収録の許可が必要です。システム設定 > プライバシーとセキュリティ > 画面収録 で有効にしてください。"
        case .accessibilityPermissionDenied:
            return "アクセシビリティの許可が必要です。システム設定 > プライバシーとセキュリティ > アクセシビリティ で有効にしてください。"
        case .captureFailedNoDisplays:
            return "キャプチャ対象のディスプレイが見つかりません。"
        case .captureFailedNoWindow:
            return "アクティブなウィンドウが見つかりません。"
        case .captureFailedInvalidRegion:
            return "選択した範囲が無効です。"
        case .captureFailed(let error):
            return "キャプチャに失敗しました: \(error.localizedDescription)"
        case .exportNoDestination:
            return "保存先が設定されていません。設定のファイルタブでフォルダを選択してください。"
        case .exportBookmarkStale:
            return "保存フォルダへのアクセス権が無効になりました。設定のファイルタブでフォルダを再選択してください。"
        case .exportWriteFailed(let error):
            return "ファイルの保存に失敗しました: \(error.localizedDescription)"
        case .exportClipboardFailed:
            return "クリップボードへのコピーに失敗しました。"
        }
    }
}
