import SwiftUI
import AppKit
import OSLog

struct FileSettingsView: View {
    @Bindable private var preferences = AppPreferences.shared
    @State private var previewName: String = ""

    var body: some View {
        Form {
            Section("保存フォルダ") {
                HStack {
                    Text(resolvedFolderPath)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("選択…") {
                        chooseSaveFolder()
                    }
                }
            }

            Section("ファイル名") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("命名テンプレート", text: $preferences.namingTemplate)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: preferences.namingTemplate) { _, _ in
                            updatePreview()
                        }

                    Text("プレビュー: \(previewName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("変数: ${YYYY} ${MM} ${DD} ${hh} ${mm} ${ss} ${index}")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear { updatePreview() }
    }

    private var resolvedFolderPath: String {
        guard let bookmarkData = preferences.saveFolderBookmark else {
            return "未設定"
        }
        var isStale = false
        let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return url?.path ?? "未設定"
    }

    private func chooseSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "選択"

        // runModal() はSwiftUIウィンドウと競合することがあるため非同期 begin() を使用
        panel.begin { [self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                preferences.saveFolderBookmark = bookmarkData
                Task { await BookmarkManager.shared.invalidateCache() }
            } catch {
                Logger.settings.error("Failed to create bookmark: \(error)")
            }
        }
    }

    private func updatePreview() {
        let template = preferences.namingTemplate
        let now = Date()
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        var result = template
        result = result.replacingOccurrences(of: "${YYYY}", with: String(format: "%04d", components.year ?? 0))
        result = result.replacingOccurrences(of: "${MM}", with: String(format: "%02d", components.month ?? 0))
        result = result.replacingOccurrences(of: "${DD}", with: String(format: "%02d", components.day ?? 0))
        result = result.replacingOccurrences(of: "${hh}", with: String(format: "%02d", components.hour ?? 0))
        result = result.replacingOccurrences(of: "${mm}", with: String(format: "%02d", components.minute ?? 0))
        result = result.replacingOccurrences(of: "${ss}", with: String(format: "%02d", components.second ?? 0))
        result = result.replacingOccurrences(of: "${index}", with: "001")
        previewName = result + "." + preferences.exportFormat.fileExtension
    }
}
