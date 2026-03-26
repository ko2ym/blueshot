import SwiftUI

struct HotKeySettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var config: HotKeyConfiguration = .default
    @State private var conflictWarning: String? = nil

    var body: some View {
        Form {
            Section("キャプチャショートカット") {
                ForEach(CaptureAction.allCases, id: \.self) { action in
                    HStack {
                        Text(action.localizedTitle)
                            .frame(width: 180, alignment: .leading)
                        Spacer()
                        HotKeyRecorderView(
                            currentBinding: config.bindings[action],
                            isReserved: isReserved(action),
                            onRecord: { binding in
                                save(action: action, binding: binding)
                            }
                        )
                    }
                }
            }

            if let warning = conflictWarning {
                Section {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            Section {
                Button("デフォルトに戻す") {
                    resetToDefaults()
                }
                .foregroundStyle(.red)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• ショートカット欄をクリックして新しいキーの組み合わせを入力してください。")
                    Text("• Escape キーで入力をキャンセルできます。")
                    Text("• ⌘⇧3/4/5 は macOS に予約されており使用できません。")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear { loadConfig() }
    }

    // MARK: - Helpers

    private func isReserved(_ action: CaptureAction) -> Bool {
        guard let binding = config.bindings[action] else { return false }
        return env.captureCoordinator.hotKeyManager.isReserved(binding)
    }

    private func save(action: CaptureAction, binding: HotKeyBinding) {
        if env.captureCoordinator.hotKeyManager.isReserved(binding) {
            conflictWarning = "\(binding.displayString) は macOS に予約されており使用できません。"
            return
        }
        if let existing = env.captureCoordinator.hotKeyManager.conflictingAction(for: binding),
           existing != action {
            conflictWarning = "\(binding.displayString) はすでに「\(existing.localizedTitle)」で使用されています。"
        } else {
            conflictWarning = nil
        }

        var newBindings = config.bindings
        newBindings[action] = binding
        config = HotKeyConfiguration(bindings: newBindings)
        env.preferences.saveHotKeyConfiguration(config)
        env.captureCoordinator.reloadHotKeys()
    }

    private func resetToDefaults() {
        config = .default
        env.preferences.saveHotKeyConfiguration(config)
        env.captureCoordinator.reloadHotKeys()
        conflictWarning = nil
    }

    private func loadConfig() {
        config = env.preferences.makeHotKeyConfiguration()
    }
}
