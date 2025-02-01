import Foundation
import UIKit

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

public typealias LogMessageBuilder = () -> Any

public class LogUtil {
    public static var captureScreenWhenError = false
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
    
    private static func processLogContent(_ message: Any) -> (String, String) {
        if let stringMessage = message as? String {
            return (stringMessage, "text")
        } else if let image = message as? UIImage, let imageData = image.pngData() {
            let base64String = imageData.base64EncodedString()
            return (base64String, "image")
        } else {
            if let jsonData = try? JSONSerialization.data(withJSONObject: message),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return (jsonString, "object")
            } else {
                return (String(describing: message), "object")
            }
        }
    }
    
    private static func log(tag: String, level: LogLevel, messageBuilder: @escaping LogMessageBuilder) {
        guard shouldLog(level) else { return }
        
        let message = messageBuilder()
        let deviceId = DeviceUtil.getDeviceId()
        let msgId = UUID().uuidString
        let createdAt = Int64(Date().timeIntervalSince1970 * 1000)
        
        let (content, contentType) = processLogContent(message)
        
        let consoleMessage = ProtoConsole(
            logTag: tag,
            logContent: content,
            logContentType: contentType,
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
        if captureScreenWhenError {
            debug(tag: tag) {
                let scene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                let window = scene?.windows.first(where: { $0.isKeyWindow })
                if let image = window?.consolebus_snapshot() {
                    return image
                }
                return ""
            }
        }
        log(tag: tag, level: .error, messageBuilder: message)
    }
}

extension UIView {
    func consolebus_snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
