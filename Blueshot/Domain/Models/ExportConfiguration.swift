import Foundation

enum ExportDestination: String, CaseIterable, Codable {
    case clipboardOnly = "clipboard"
    case folderOnly = "folder"
    case both = "both"

    var localizedTitle: String {
        switch self {
        case .clipboardOnly: return "クリップボードのみ"
        case .folderOnly: return "フォルダに保存"
        case .both: return "クリップボード & フォルダに保存"
        }
    }
}

enum ExportFormat: String, CaseIterable, Codable {
    case png
    case jpeg

    var fileExtension: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        }
    }
}

struct ExportConfiguration: Sendable {
    let destination: ExportDestination
    let format: ExportFormat
    let jpegQuality: Double
    let namingTemplate: String

    static let `default` = ExportConfiguration(
        destination: .clipboardOnly,
        format: .png,
        jpegQuality: 0.9,
        namingTemplate: "Screenshot_${YYYY}${MM}${DD}_${hh}${mm}${ss}"
    )
}
