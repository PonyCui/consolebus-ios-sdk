import Foundation

public class ProtoConsole: ProtoMessageBase {
    public let logTag: String
    public let logContent: String
    public let logContentType: String // text/image/object
    public let logLevel: String // debug/info/warn/error
    
    public init(logTag: String = "", logContent: String, logContentType: String, logLevel: String, deviceId: String, msgId: String, createdAt: Int64) {
        self.logTag = logTag
        self.logContent = logContent
        self.logContentType = logContentType
        self.logLevel = logLevel
        super.init(deviceId: deviceId, msgId: msgId, featureId: "console", createdAt: createdAt)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public override func toJson() -> [String: Any] {
        var json = super.toJson()
        json["logTag"] = logTag
        json["logContent"] = logContent
        json["logContentType"] = logContentType
        json["logLevel"] = logLevel
        return json
    }
    
    public static func fromJSON(_ json: [String: Any]) -> ProtoConsole? {
        guard let logContent = json["logContent"] as? String,
              let logContentType = json["logContentType"] as? String,
              let logLevel = json["logLevel"] as? String,
              let deviceId = json["deviceId"] as? String,
              let msgId = json["msgId"] as? String,
              let createdAt = json["createdAt"] as? Int64 else {
            return nil
        }
        
        let logTag = json["logTag"] as? String ?? ""
        
        return ProtoConsole(
            logTag: logTag,
            logContent: logContent,
            logContentType: logContentType,
            logLevel: logLevel,
            deviceId: deviceId,
            msgId: msgId,
            createdAt: createdAt
        )
    }
}
