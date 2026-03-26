import OSLog

extension Logger {
    private static let subsystem = "com.blueshot.app"

    static let capture = Logger(subsystem: subsystem, category: "Capture")
    static let editor = Logger(subsystem: subsystem, category: "Editor")
    static let export = Logger(subsystem: subsystem, category: "Export")
    static let hotKey = Logger(subsystem: subsystem, category: "HotKey")
    static let permission = Logger(subsystem: subsystem, category: "Permission")
    static let settings = Logger(subsystem: subsystem, category: "Settings")
}
