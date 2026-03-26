import Foundation

/// All available drawing tools in the editor.
enum DrawingTool: String, CaseIterable, Sendable {
    case rectangle
    case arrow
    case text
    case highlight
    case blur
    case mosaic

    var iconName: String {
        switch self {
        case .rectangle: return "rectangle"
        case .arrow: return "arrow.up.right"
        case .text: return "textformat"
        case .highlight: return "highlighter"
        case .blur: return "aqi.medium"
        case .mosaic: return "squareshape.split.3x3"
        }
    }

    var localizedTitle: String {
        switch self {
        case .rectangle: return "四角形"
        case .arrow: return "矢印"
        case .text: return "テキスト"
        case .highlight: return "ハイライト"
        case .blur: return "ぼかし"
        case .mosaic: return "モザイク"
        }
    }
}
