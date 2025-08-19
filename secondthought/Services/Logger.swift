import Foundation

enum LogLevel: String, CaseIterable {
    case debug = "🔵"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
    case success = "✅"
    case timer = "⏰"
    case blocking = "🚫"
    case unblocking = "🔓"
    case shield = "🛡️"
    case storage = "💾"
    case intent = "🎯"
    case ui = "🖥️"
}

class Logger {
    static let shared = Logger()
    
    private let isDebugMode: Bool
    
    private init() {
        #if DEBUG
        isDebugMode = true
        #else
        isDebugMode = false
        #endif
    }
    
    func log(_ level: LogLevel, _ message: String, context: String = "") {
        guard isDebugMode else { return }
        
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let contextPrefix = context.isEmpty ? "" : "[\(context)] "
        print("\(level.rawValue) \(timestamp) \(contextPrefix)\(message)")
    }
    
    func debug(_ message: String, context: String = "") {
        log(.debug, message, context: context)
    }
    
    func info(_ message: String, context: String = "") {
        log(.info, message, context: context)
    }
    
    func warning(_ message: String, context: String = "") {
        log(.warning, message, context: context)
    }
    
    func error(_ message: String, context: String = "") {
        log(.error, message, context: context)
    }
    
    func success(_ message: String, context: String = "") {
        log(.success, message, context: context)
    }
    
    func timer(_ message: String, context: String = "") {
        log(.timer, message, context: context)
    }
    
    func blocking(_ message: String, context: String = "") {
        log(.blocking, message, context: context)
    }
    
    func unblocking(_ message: String, context: String = "") {
        log(.unblocking, message, context: context)
    }
    
    func shield(_ message: String, context: String = "") {
        log(.shield, message, context: context)
    }
    
    func storage(_ message: String, context: String = "") {
        log(.storage, message, context: context)
    }
    
    func intent(_ message: String, context: String = "") {
        log(.intent, message, context: context)
    }
    
    func ui(_ message: String, context: String = "") {
        log(.ui, message, context: context)
    }
}

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}