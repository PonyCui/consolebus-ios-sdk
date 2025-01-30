import Foundation

public class ProtoMessageBase: NSObject, Codable {
    public let deviceId: String
    public let msgId: String
    public let featureId: String
    public let createdAt: Int64 // unit = ms
    
    public init(deviceId: String, msgId: String, featureId: String, createdAt: Int64) {
        self.deviceId = deviceId
        self.msgId = msgId
        self.featureId = featureId
        self.createdAt = createdAt
        super.init()
    }
    
    public func toJson() -> [String: Any] {
        return [
            "deviceId": deviceId,
            "msgId": msgId,
            "featureId": featureId,
            "createdAt": createdAt
        ]
    }
    
    public func toJSONString() -> String? {
        let jsonDict = self.toJson()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
