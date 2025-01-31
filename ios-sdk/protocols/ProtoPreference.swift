import Foundation

public class ProtoPreference: ProtoMessageBase {
    public let key: String
    public let value: Any
    public let operation: String // 'set' or 'get' or 'sync'
    public let type: String // 'string', 'number', 'boolean', 'map', 'list', 'null'
    
    public init(key: String, value: Any, operation: String, type: String, deviceId: String, msgId: String, createdAt: Int64) {
        self.key = key
        self.value = value
        self.operation = operation
        self.type = type
        super.init(deviceId: deviceId, msgId: msgId, featureId: "preference", createdAt: createdAt)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public override func toJson() -> [String: Any] {
        var json = super.toJson()
        json["key"] = key
        json["value"] = value
        json["operation"] = operation
        json["type"] = type
        return json
    }
    
    public static func fromJSON(_ json: [String: Any]) -> ProtoPreference? {
        guard let key = json["key"] as? String,
              let operation = json["operation"] as? String,
              let type = json["type"] as? String,
              let deviceId = json["deviceId"] as? String,
              let msgId = json["msgId"] as? String,
              let createdAt = json["createdAt"] as? Int64 else {
            return nil
        }
        
        let value = json["value"]
        
        return ProtoPreference(
            key: key,
            value: value ?? NSNull(),
            operation: operation,
            type: type,
            deviceId: deviceId,
            msgId: msgId,
            createdAt: createdAt
        )
    }
    
    public override var description: String {
        return "ProtoPreference{key: \(key), value: \(value), type: \(type), operation: \(operation)}"
    }
}
