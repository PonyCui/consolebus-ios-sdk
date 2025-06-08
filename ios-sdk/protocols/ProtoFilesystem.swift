import Foundation

struct ProtoFilesystemEntry: Codable {
    let name: String
    let isDirectory: Bool
    let size: Int?
    let modifiedAt: Int64? // Unix timestamp (milliseconds since epoch)

    init(name: String, isDirectory: Bool, size: Int? = nil, modifiedAt: Int64? = nil) {
        self.name = name
        self.isDirectory = isDirectory
        self.size = size
        self.modifiedAt = modifiedAt
    }
}

public class ProtoFilesystem: ProtoMessageBase {
    let path: String
    let operation: String // e.g., "list", "read", "write", "delete", "list_response", "read_response", etc.
    var entries: [ProtoFilesystemEntry]? // For "list_response"
    var content: String? // For "read_response" (file content) or "write" (content to write)
    var error: String? // For responses, to indicate an error
    var newPath: String? // For "rename" or "move" operations

    init(path: String, operation: String, entries: [ProtoFilesystemEntry]? = nil, content: String? = nil, error: String? = nil, newPath: String? = nil, deviceId: String, msgId: String, featureId: String, createdAt: Int64) {
        self.path = path
        self.operation = operation
        self.entries = entries
        self.content = content
        self.error = error
        self.newPath = newPath
        super.init(deviceId: deviceId, msgId: msgId, featureId: featureId, createdAt: createdAt)
    }

    // Convenience initializer from a dictionary (e.g., parsed JSON)
    public static func fromJSON(_ json: [String: Any]) -> ProtoFilesystem? {
        guard let path = json["path"] as? String,
              let operation = json["operation"] as? String,
              let deviceId = json["deviceId"] as? String,
              let msgId = json["msgId"] as? String,
              let featureId = json["featureId"] as? String,
              let createdAt = json["createdAt"] as? Int64 else {
            return nil
        }

        var parsedEntries: [ProtoFilesystemEntry]? = nil
        if let entriesArray = json["entries"] as? [[String: Any]] {
            parsedEntries = entriesArray.compactMap { entryDict -> ProtoFilesystemEntry? in
                guard let name = entryDict["name"] as? String,
                      let isDirectory = entryDict["isDirectory"] as? Bool else {
                    return nil
                }
                let size = entryDict["size"] as? Int
                let modifiedAt = entryDict["modifiedAt"] as? Int64
                return ProtoFilesystemEntry(name: name, isDirectory: isDirectory, size: size, modifiedAt: modifiedAt)
            }
        }
        
        let content = json["content"] as? String
        let error = json["error"] as? String
        let newPath = json["newPath"] as? String

        return ProtoFilesystem(path: path, operation: operation, entries: parsedEntries, content: content, error: error, newPath: newPath, deviceId: deviceId, msgId: msgId, featureId: featureId, createdAt: createdAt)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public override func toJson() -> [String: Any] {
        var json = super.toJson()
        json["path"] = path
        json["operation"] = operation
        if let entries = entries {
            json["entries"] = entries.map { $0.toDictionary() }
        }
        if let content = content {
            json["content"] = content
        }
        if let error = error {
            json["error"] = error
        }
        if let newPath = newPath {
            json["newPath"] = newPath
        }
        return json
    }
}

extension ProtoFilesystemEntry {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "isDirectory": isDirectory
        ]
        if let size = size {
            dict["size"] = size
        }
        if let modifiedAt = modifiedAt {
            dict["modifiedAt"] = modifiedAt
        }
        return dict
    }
}
