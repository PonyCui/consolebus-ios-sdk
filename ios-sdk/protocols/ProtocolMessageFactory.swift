import Foundation

public class ProtocolMessageFactory {
    public static func fromJSON(_ json: [String: Any]) -> ProtoMessageBase? {
        guard let featureId = json["featureId"] as? String else {
            return nil
        }
        
        switch featureId {
        case "console":
            return ProtoConsole.fromJSON(json)
        case "device":
            return ProtoDevice.fromJSON(json)
        case "preference":
            return ProtoPreference.fromJSON(json)
        case "filesystem":
            return ProtoFilesystem.fromJSON(json)
        default:
            return nil
        }
    }
}
