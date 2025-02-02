//
//  LocalFileManager.swift
//  ios-sdk
//
//  Created by PonyCui on 2025/1/30.
//

import Foundation

public class LocalFileManagerConfig {
    public let maxDaysToKeep: Int?
    public let maxFolderSizeMB: Int?
    public let batchDeleteCount: Int
    
    public init(maxDaysToKeep: Int? = nil, maxFolderSizeMB: Int? = nil, batchDeleteCount: Int = 10) {
        self.maxDaysToKeep = maxDaysToKeep
        self.maxFolderSizeMB = maxFolderSizeMB
        self.batchDeleteCount = batchDeleteCount
    }
}

public class LocalFileManager {
    private static let fileManager = FileManager.default
    
    public static func cleanLogFiles(config: LocalFileManagerConfig) {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let logDir = cacheDir.appendingPathComponent("console-bus-log")
        guard fileManager.fileExists(atPath: logDir.path) else { return }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: logDir,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            // 按创建时间排序
            let sortedFiles = try fileURLs.map { url -> (URL, Date, Int64) in
                let attributes = try url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                return (url,
                        attributes.creationDate ?? Date.distantPast,
                        Int64(attributes.fileSize ?? 0))
            }.sorted { $0.1 < $1.1 }
            
            // 基于时间的清理
            if let maxDays = config.maxDaysToKeep {
                let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
                let oldFiles = sortedFiles.filter { $0.1 < cutoffDate }
                for (fileURL, _, _) in oldFiles {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
            
            // 基于空间的清理
            if let maxSizeMB = config.maxFolderSizeMB {
                var currentSize: Int64 = 0
                var filesToDelete: [(URL, Date, Int64)] = []
                
                for file in sortedFiles {
                    currentSize += file.2
                    if currentSize > Int64(maxSizeMB * 1024 * 1024) {
                        filesToDelete.append(file)
                        if filesToDelete.count >= config.batchDeleteCount {
                            break
                        }
                    }
                }
                
                for (fileURL, _, _) in filesToDelete {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("Error cleaning log files: \(error)")
        }
    }
}
