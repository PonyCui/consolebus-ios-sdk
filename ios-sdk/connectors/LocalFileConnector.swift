import Foundation

public class LocalFileConnector: MessageConnector {
    private let flushInterval: TimeInterval = 5.0 // 定时刷新间隔（秒）
    private var flushTimer: Timer?
    private let fileURL: URL
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.consolebus.localfileconnector", qos: .utility)
    
    public init(filename: String? = nil) {
        // 获取 Cache 目录
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let logDir = cacheDir.appendingPathComponent("console-bus-log")
        
        // 创建日志目录
        try? fileManager.createDirectory(at: logDir, withIntermediateDirectories: true)
        
        // 生成文件名
        let actualFilename: String
        if let filename = filename {
            actualFilename = filename + ".cblog"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            actualFilename = "\(dateFormatter.string(from: Date())).cblog"
        }
        
        self.fileURL = logDir.appendingPathComponent(actualFilename)
        super.init(maxBufferSize: 50)
        
        // 启动定时器
        startFlushTimer()
    }
    
    deinit {
        stopFlushTimer()
        flushBuffer() // 确保所有消息都被写入
    }
    
    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flushBuffer()
        }
    }
    
    private func stopFlushTimer() {
        flushTimer?.invalidate()
        flushTimer = nil
    }
    
    public override func send(message: String) {
        queue.async { [weak self] in
            self?.addToBuffer(message)
        }
    }
    
    internal override func addToBuffer(_ message: String) {
        super.addToBuffer(message)
        
        // 如果缓冲区超出大小限制，强制刷新
        if messageBuffer.count >= maxBufferSize {
            flushBuffer()
        }
    }
    
    private func flushBuffer() {
        guard !messageBuffer.isEmpty else { return }
        
        let messages = messageBuffer.map { $0.message + "\n" }
        messageBuffer.removeAll()
        
        do {
            // 如果文件不存在，创建文件
            if !fileManager.fileExists(atPath: fileURL.path) {
                fileManager.createFile(atPath: fileURL.path, contents: nil)
            }
            
            // 追加写入文件
            let handle = try FileHandle(forWritingTo: fileURL)
            handle.seekToEndOfFile()
            
            for message in messages {
                if let data = message.data(using: .utf8) {
                    handle.write(data)
                }
            }
            
            try handle.close()
        } catch {
            onError?(error)
            // 发生错误时，将消息放回缓冲区
            for message in messages {
                addToBuffer(message.trimmingCharacters(in: .newlines))
            }
        }
    }

    public func sendMessage(_ message: ProtoMessageBase) {
        if let jsonString = message.toJSONString() {
            send(message: jsonString)
        } else {
            print("Error: Could not serialize ProtoMessageBase to JSON string")
            // Optionally, handle the error, e.g., by sending an error message back or logging
        }
    }
    
    public override func stop() {
        stopFlushTimer()
        flushBuffer()
    }
}
