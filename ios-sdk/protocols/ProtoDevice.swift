import Foundation

public class ProtoDevice: ProtoMessageBase {
    public let deviceName: String
    public let deviceType: String
    
    public init(deviceName: String, deviceType: String, deviceId: String, msgId: String, createdAt: Int64) {
        self.deviceName = deviceName
        self.deviceType = deviceType
        super.init(deviceId: deviceId, msgId: msgId, featureId: "device", createdAt: createdAt)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public override func toJson() -> [String: Any] {
        var json = super.toJson()
        json["deviceName"] = deviceName
        json["deviceType"] = deviceType
        return json
    }
    
    public static func fromJSON(_ json: [String: Any]) -> ProtoDevice? {
        guard let deviceName = json["deviceName"] as? String,
              let deviceType = json["deviceType"] as? String,
              let deviceId = json["deviceId"] as? String,
              let msgId = json["msgId"] as? String,
              let createdAt = json["createdAt"] as? Int64 else {
            return nil
        }
        
        return ProtoDevice(
            deviceName: deviceName,
            deviceType: deviceType,
            deviceId: deviceId,
            msgId: msgId,
            createdAt: createdAt
        )
    }
}
