import Foundation
import Observation

@MainActor
@Observable
final class AppPreferences {
    // MARK: - Singleton
    static let shared = AppPreferences()

    // MARK: - Keys
    private enum Keys {
        static let exportDestination      = "exportDestination"
        static let exportFormat           = "exportFormat"
        static let jpegQuality            = "jpegQuality"
        static let namingTemplate         = "namingTemplate"
        static let saveFolderBookmark     = "saveFolderBookmark"
        static let hotKeyBindings         = "hotKeyBindings"
        static let openEditorAfterCapture = "openEditorAfterCapture"
        static let includeMouseCursor     = "includeMouseCursor"
        static let captureDelaySeconds    = "captureDelaySeconds"

    }

    private let defaults = UserDefaults.standard

    // MARK: - Export Settings
    // stored property にすることで @Observable が変更を追跡し SwiftUI が再描画される
    var exportDestination: ExportDestination = .clipboardOnly {
        didSet { defaults.set(exportDestination.rawValue, forKey: Keys.exportDestination) }
    }

    var exportFormat: ExportFormat = .png {
        didSet { defaults.set(exportFormat.rawValue, forKey: Keys.exportFormat) }
    }

    var jpegQuality: Double = 0.9 {
        didSet { defaults.set(jpegQuality, forKey: Keys.jpegQuality) }
    }

    var namingTemplate: String = "Screenshot_${YYYY}${MM}${DD}_${hh}${mm}${ss}" {
        didSet { defaults.set(namingTemplate, forKey: Keys.namingTemplate) }
    }

    // MARK: - Folder Bookmark
    var saveFolderBookmark: Data? = nil {
        didSet { defaults.set(saveFolderBookmark, forKey: Keys.saveFolderBookmark) }
    }

    // MARK: - HotKey Settings
    var hotKeyBindings: [String: [String: UInt32]] = [:] {
        didSet { defaults.set(hotKeyBindings, forKey: Keys.hotKeyBindings) }
    }

    // MARK: - Behavior Settings
    var openEditorAfterCapture: Bool = true {
        didSet { defaults.set(openEditorAfterCapture, forKey: Keys.openEditorAfterCapture) }
    }

    var includeMouseCursor: Bool = false {
        didSet { defaults.set(includeMouseCursor, forKey: Keys.includeMouseCursor) }
    }

    var captureDelaySeconds: Int = 0 {
        didSet { defaults.set(captureDelaySeconds, forKey: Keys.captureDelaySeconds) }
    }

    // MARK: - Init (didSet は init 内では呼ばれない)
    private init() {
        if let raw = defaults.string(forKey: Keys.exportDestination),
           let value = ExportDestination(rawValue: raw) {
            exportDestination = value
        }
        if let raw = defaults.string(forKey: Keys.exportFormat),
           let value = ExportFormat(rawValue: raw) {
            exportFormat = value
        }
        if let quality = defaults.object(forKey: Keys.jpegQuality) as? Double {
            jpegQuality = quality
        }
        if let template = defaults.string(forKey: Keys.namingTemplate), !template.isEmpty {
            namingTemplate = template
        }
        saveFolderBookmark = defaults.data(forKey: Keys.saveFolderBookmark)
        if let bindings = defaults.dictionary(forKey: Keys.hotKeyBindings) as? [String: [String: UInt32]] {
            hotKeyBindings = bindings
        }
        if let openEditor = defaults.object(forKey: Keys.openEditorAfterCapture) as? Bool {
            openEditorAfterCapture = openEditor
        }
        includeMouseCursor = defaults.bool(forKey: Keys.includeMouseCursor)
        // captureDelaySeconds: 0 はデフォルト値でもあるため object(forKey:) で確認
        if let delay = defaults.object(forKey: Keys.captureDelaySeconds) as? Int {
            captureDelaySeconds = delay
        }
    }

    // MARK: - Factory Methods
    func makeExportConfiguration() -> ExportConfiguration {
        ExportConfiguration(
            destination: exportDestination,
            format: exportFormat,
            jpegQuality: jpegQuality,
            namingTemplate: namingTemplate
        )
    }

    func makeHotKeyConfiguration() -> HotKeyConfiguration {
        var bindings: [CaptureAction: HotKeyBinding] = [:]
        for action in CaptureAction.allCases {
            if let entry = hotKeyBindings[action.rawValue],
               let keyCode = entry["keyCode"],
               let modifiers = entry["modifiers"] {
                bindings[action] = HotKeyBinding(keyCode: keyCode, modifiers: modifiers)
            }
        }
        return bindings.isEmpty ? .default : HotKeyConfiguration(bindings: bindings)
    }

    func saveHotKeyConfiguration(_ config: HotKeyConfiguration) {
        var stored: [String: [String: UInt32]] = [:]
        for (action, binding) in config.bindings {
            stored[action.rawValue] = ["keyCode": binding.keyCode, "modifiers": binding.modifiers]
        }
        hotKeyBindings = stored
    }

    // MARK: - Reset
    func resetToDefaults() {
        exportDestination      = .clipboardOnly
        exportFormat           = .png
        jpegQuality            = 0.9
        namingTemplate         = "Screenshot_${YYYY}${MM}${DD}_${hh}${mm}${ss}"
        saveFolderBookmark     = nil
        hotKeyBindings         = [:]
        openEditorAfterCapture = true
        includeMouseCursor     = false
        captureDelaySeconds    = 0
    }
}
