import Foundation

public class MessageConnector: NSObject {
    // 消息缓冲区
    var messageBuffer: [(message: String, timestamp: TimeInterval)] = []
    var maxBufferSize: Int
    
    // 错误处理回调
    public var onError: ((Error) -> Void)?
    
    public init(maxBufferSize: Int) {
        self.maxBufferSize = maxBufferSize
        super.init()
    }
    
    // 发送消息的抽象方法
    public func send(message: String) {
        fatalError("send(message:) must be overridden by subclass")
    }
    
    // 停止连接的抽象方法
    public func stop() {
        fatalError("stop() must be overridden by subclass")
    }
    
    // 添加消息到缓冲区
    func addToBuffer(_ message: String) {
        let timestamp = Date().timeIntervalSince1970
        messageBuffer.append((message: message, timestamp: timestamp))
    }
    
    // 清空缓冲区
    func clearBuffer() {
        messageBuffer.removeAll()
    }
    
    // 获取排序后的缓冲消息
    func getSortedMessages() -> [(message: String, timestamp: TimeInterval)] {
        return messageBuffer.sorted { $0.timestamp < $1.timestamp }
    }
    
    // 处理缓冲区大小限制
    func handleBufferLimit() {
        if messageBuffer.count > maxBufferSize {
            messageBuffer.removeFirst()
        }
    }
}
