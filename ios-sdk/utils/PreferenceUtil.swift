import Foundation

public class PreferenceUtil {
    
    private static var connector: WebSocketConnector? {
        return ConsoleBusIOSSDK.activeSDKInstance?.connector
    }
    
    public static func getValueType(_ value: Any) -> String {
        switch value {
        case is String:
            return "string"
        case is Int, is Double, is Float, is Int32, is Int64:
            return "number"
        case is Bool:
            return "boolean"
        case is [String: Any]:
            return "map"
        case is [Any]:
            return "list"
        case is NSNull:
            return "null"
        default:
            return "string"
        }
    }
    
    public static func onGetKeyValue(key: String, value: Any) {
        let type = getValueType(value)
        let proto = ProtoPreference(
            key: key,
            value: value,
            operation: "get",
            type: type,
            deviceId: DeviceUtil.getDeviceId(),
            msgId: UUID().uuidString,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        connector?.send(message: proto.toJSONString() ?? "")
    }
}
