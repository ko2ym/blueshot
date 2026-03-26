import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @Bindable private var preferences = AppPreferences.shared
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        Form {
            Section("起動") {
                Toggle("ログイン時に自動起動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }

            Section("出力") {
                Picker("保存先", selection: $preferences.exportDestination) {
                    ForEach(ExportDestination.allCases, id: \.self) { dest in
                        Text(dest.localizedTitle).tag(dest)
                    }
                }
                .pickerStyle(.radioGroup)

                Picker("形式", selection: $preferences.exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { fmt in
                        Text(fmt.localizedTitle).tag(fmt)
                    }
                }
                .pickerStyle(.segmented)

                if preferences.exportFormat == .jpeg {
                    HStack {
                        Text("JPEG 品質")
                        Slider(value: $preferences.jpegQuality, in: 0.1...1.0, step: 0.05)
                        Text("\(Int(preferences.jpegQuality * 100))%")
                            .monospacedDigit()
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }

            Section("動作") {
                Toggle("キャプチャ後にエディタを開く", isOn: $preferences.openEditorAfterCapture)
                Toggle("マウスカーソルを含める", isOn: $preferences.includeMouseCursor)
                Picker("キャプチャの遅延", selection: $preferences.captureDelaySeconds) {
                    Text("なし").tag(0)
                    Text("1 秒").tag(1)
                    Text("3 秒").tag(3)
                    Text("5 秒").tag(5)
                    Text("10 秒").tag(10)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
