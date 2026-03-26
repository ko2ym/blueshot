import SwiftUI

struct SettingsView: View {
    private enum Tab: String, CaseIterable {
        case general = "一般"
        case file = "ファイル"
        case hotKeys = "ショートカット"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .file: return "folder"
            case .hotKeys: return "keyboard"
            }
        }
    }

    var body: some View {
        TabView {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .frame(width: 480, height: 320)
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .general:
            GeneralSettingsView()
        case .file:
            FileSettingsView()
        case .hotKeys:
            HotKeySettingsView()
        }
    }
}
