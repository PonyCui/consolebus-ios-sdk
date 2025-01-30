import Foundation

public enum LogLevel: String {
    case debug = "debug"
    case info = "info"
    case warn = "warn"
    case error = "error"
    
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warn: return 2
        case .error: return 3
        }
    }
}

public typealias LogMessageBuilder = () -> String

public class LogUtil {
    private static var minimumLogLevel: LogLevel = .debug
    private static var connector: WebSocketConnector? {
        return ConsoleBusIOSSDK.activeSDKInstance?.connector
    }
    
    public static func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }
    
    private static func shouldLog(_ level: LogLevel) -> Bool {
        return level.priority >= minimumLogLevel.priority
    }
    
    private static func log(tag: String, level: LogLevel, messageBuilder: @escaping LogMessageBuilder) {
        guard shouldLog(level) else { return }
        
        let message = messageBuilder()
        let deviceId = DeviceUtil.getDeviceId()
        let msgId = UUID().uuidString
        let createdAt = Int64(Date().timeIntervalSince1970 * 1000)
        
        let consoleMessage = ProtoConsole(
            logTag: tag,
            logContent: message,
            logLevel: level.rawValue,
            deviceId: deviceId,
            msgId: msgId,
            createdAt: createdAt
        )
        
        connector?.send(message: consoleMessage.toJSONString() ?? "")
    }
    
    public static func debug(tag: String = "", message: @escaping LogMessageBuilder) {
        log(tag: tag, level: .debug, messageBuilder: message)
    }
    
    public static func info(tag: String = "", message: @escaping LogMessageBuilder) {
        log(tag: tag, level: .info, messageBuilder: message)
    }
    
    public static func warn(tag: String = "", message: @escaping LogMessageBuilder) {
        log(tag: tag, level: .warn, messageBuilder: message)
    }
    
    public static func error(tag: String = "", message: @escaping LogMessageBuilder) {
        log(tag: tag, level: .error, messageBuilder: message)
    }
}
