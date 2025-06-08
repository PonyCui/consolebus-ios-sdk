import Foundation

class FilesystemFeatureHandler: FeatureHandler {
    private var directoryMappings: [String: URL] = [:]
    private let fileManager = FileManager.default

    public init() {
        // Setup default mappings for "caches" and "tmp"
        // These can be overridden or augmented by the configure() method.
        if let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            self.directoryMappings["caches"] = cachesDir.standardizedFileURL
        }
        let tmpDirString = NSTemporaryDirectory()
        let tmpDirURL = URL(fileURLWithPath: tmpDirString, isDirectory: true)
        self.directoryMappings["tmp"] = tmpDirURL.standardizedFileURL
    }

    public func configure(mappings: [String: URL]) {
        for (key, url) in mappings {
            let cleanKey = key.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !cleanKey.isEmpty {
                self.directoryMappings[cleanKey] = url.standardizedFileURL
            }
        }
    }

    private func resolvePath(_ relativePath: String) -> (url: URL?, error: String?) {
        let urlFromPath = URL(fileURLWithPath: relativePath)
        var pathComponents = urlFromPath.pathComponents

        guard !pathComponents.isEmpty, pathComponents[0] == "/" else {
            return (nil, "Path must be absolute and start with a registered prefix (e.g., /caches/file.txt). Path provided: \(relativePath)")
        }

        pathComponents.removeFirst() // Remove leading "/"

        guard !pathComponents.isEmpty else {
            return (nil, "Path cannot be just '/'. It must include a prefix (e.g., /caches/file.txt). Path provided: \(relativePath)")
        }

        let prefix = pathComponents[0]
        
        guard let baseDirectoryURL = directoryMappings[prefix] else {
            let availablePrefixes = directoryMappings.keys.isEmpty ? "None configured." : directoryMappings.keys.sorted().joined(separator: ", ")
            return (nil, "Unknown path prefix '\(prefix)'. Path: \(relativePath). Supported prefixes: [\(availablePrefixes)]")
        }

        let subPathComponents = Array(pathComponents.dropFirst())
        let finalSubPath = subPathComponents.joined(separator: "/")
        
        let resolvedURL = baseDirectoryURL.appendingPathComponent(finalSubPath).standardizedFileURL
        
        let standardizedBasePath = baseDirectoryURL.standardizedFileURL.path
        let standardizedResolvedPath = resolvedURL.path

        // Security check: Ensure resolved path is within or at the base directory.
        if !standardizedResolvedPath.hasPrefix(standardizedBasePath) {
             // This check catches cases where resolved path is outside the base directory (e.g. /foo/other when base is /foo/bar)
             // or traversal like /foo when base is /foo/bar/baz
             // It's true if /foo/bar/file.txt starts with /foo/bar/
             // It's true if /foo/bar starts with /foo/bar/
             // It's false if /foo starts with /foo/bar/
            return (nil, "Security check failed: Resolved path '\(standardizedResolvedPath)' is outside the designated directory for prefix '\(prefix)' ('\(standardizedBasePath)').")
        }
        
        return (resolvedURL, nil)
    }

    func handleMessage(_ message: ProtoMessageBase, from connector: MessageConnector) {
        guard let fsMessage = message as? ProtoFilesystem else {
            print("FilesystemFeatureHandler: Received non-filesystem message")
            return
        }

        print("FilesystemFeatureHandler: Received operation '\(fsMessage.operation)' for path '\(fsMessage.path)'")

        switch fsMessage.operation {
        case "list":
            handleListDirectory(fsMessage, from: connector)
        case "read":
            handleReadFile(fsMessage, from: connector)
        case "write":
            handleWriteFile(fsMessage, from: connector)
        case "delete":
            handleDeleteFile(fsMessage, from: connector)
        default:
            print("FilesystemFeatureHandler: Unknown operation '\(fsMessage.operation)'")
            let response = ProtoFilesystem(
                path: fsMessage.path,
                operation: "\(fsMessage.operation)_response",
                error: "Unknown operation",
                deviceId: fsMessage.deviceId,
                msgId: UUID().uuidString, // Respond with a new msgId
                featureId: fsMessage.featureId,
                createdAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
            connector.send(message: response.toJSONString()!)
        }
    }

    private func handleListDirectory(_ message: ProtoFilesystem, from connector: MessageConnector) {
        var responsePath = message.path
        var entries: [ProtoFilesystemEntry] = []
        var errorStr: String?

        let (resolvedURL, pathError) = resolvePath(message.path)

        if message.path == "/" {
            directoryMappings.keys.forEach { key in
                entries.append(ProtoFilesystemEntry(name: key, isDirectory: true))
            }
        } else if let err = pathError {
            errorStr = err
        } else if let url = resolvedURL {
            responsePath = url.path
            do {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if !isDirectory.boolValue {
                        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Path is not a directory."])
                    }
                } else {
                     throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Path does not exist."])
                }

                let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey, .nameKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
                for itemURL in contents {
                    let resourceValues = try? itemURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey, .nameKey])
                    
                    let itemName = resourceValues?.name ?? itemURL.lastPathComponent
                    let isDir = resourceValues?.isDirectory ?? false
                    let size = resourceValues?.fileSize
                    let modificationDate = resourceValues?.contentModificationDate
                    
                    let modifiedAt = modificationDate.map { Int64($0.timeIntervalSince1970 * 1000) }
                    entries.append(ProtoFilesystemEntry(name: itemName, isDirectory: isDir, size: size, modifiedAt: modifiedAt))
                }
            } catch {
                errorStr = error.localizedDescription
                print("Error listing directory \(url.path): \(errorStr ?? "Unknown error")")
            }
        } else {
            errorStr = "Internal error: Path resolution failed without specific error."
        }

        let response = ProtoFilesystem(
            path: responsePath,
            operation: "list_response",
            entries: entries,
            error: errorStr,
            deviceId: message.deviceId,
            msgId: UUID().uuidString,
            featureId: message.featureId,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        connector.send(message: response.toJSONString()!)
    }

    private func handleReadFile(_ message: ProtoFilesystem, from connector: MessageConnector) {
        var fileContent: String? = nil
        var errorStr: String? = nil
        var responsePath = message.path

        let (resolvedURL, pathError) = resolvePath(message.path)

        if let err = pathError {
            errorStr = err
        } else if let url = resolvedURL {
            responsePath = url.path
            do {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [NSLocalizedDescriptionKey: "Path is a directory, not a file."])
                    }
                } // If not exists, String(contentsOf:) will throw.

                fileContent = try String(contentsOf: url, encoding: .utf8)
            } catch {
                errorStr = error.localizedDescription
                print("Error reading file \(url.path): \(errorStr ?? "Unknown error")")
            }
        } else {
            errorStr = "Internal error: Path resolution failed without specific error."
        }

        let response = ProtoFilesystem(
            path: responsePath,
            operation: "read_response",
            content: fileContent,
            error: errorStr,
            deviceId: message.deviceId,
            msgId: UUID().uuidString,
            featureId: message.featureId,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        connector.send(message: response.toJSONString()!)
    }
    
    private func handleWriteFile(_ message: ProtoFilesystem, from connector: MessageConnector) {
        var errorStr: String? = nil
        var responsePath = message.path
        
        let (resolvedURL, pathError) = resolvePath(message.path)

        if let err = pathError {
            errorStr = err
        } else if let url = resolvedURL {
            responsePath = url.path
            if let contentToWrite = message.content {
                do {
                    let parentDir = url.deletingLastPathComponent()
                    if !fileManager.fileExists(atPath: parentDir.path) {
                        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
                    }
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                        throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError, userInfo: [NSLocalizedDescriptionKey: "Path is a directory, cannot write content to it as a file."])
                    }

                    try contentToWrite.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    errorStr = error.localizedDescription
                    print("Error writing file \(url.path): \(errorStr ?? "Unknown error")")
                }
            } else {
                errorStr = "No content provided to write."
            }
        } else {
            errorStr = "Internal error: Path resolution failed without specific error."
        }

        let response = ProtoFilesystem(
            path: responsePath,
            operation: "write_response",
            error: errorStr,
            deviceId: message.deviceId,
            msgId: UUID().uuidString,
            featureId: message.featureId,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        connector.send(message: response.toJSONString()!)
    }

    private func handleDeleteFile(_ message: ProtoFilesystem, from connector: MessageConnector) {
        var errorStr: String? = nil
        var responsePath = message.path

        let (resolvedURL, pathError) = resolvePath(message.path)

        if let err = pathError {
            errorStr = err
        } else if let url = resolvedURL {
            responsePath = url.path
            do {
                if !fileManager.fileExists(atPath: url.path) {
                    // Let removeItem throw the specific error if file not found
                    // throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "File or directory does not exist at path: \(url.path)"])
                }
                try fileManager.removeItem(at: url)
            } catch {
                errorStr = error.localizedDescription
                print("Error deleting item \(url.path): \(errorStr ?? "Unknown error")")
            }
        } else {
            errorStr = "Internal error: Path resolution failed without specific error."
        }

        let response = ProtoFilesystem(
            path: responsePath,
            operation: "delete_response",
            error: errorStr,
            deviceId: message.deviceId,
            msgId: UUID().uuidString,
            featureId: message.featureId,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        connector.send(message: response.toJSONString()!)
    }
    
    // Required by FeatureHandler protocol, but not used if this handler is directly registered.
    func featureIdentifier() -> String {
        return "filesystem"
    }
}
