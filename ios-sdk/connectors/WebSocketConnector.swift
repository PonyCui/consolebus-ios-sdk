import Foundation

public class WebSocketConnector: NSObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected: Bool = false
    private var shouldReconnect: Bool = false
    private var reconnectTimer: Timer?
    private var reconnectAttempt: Int = 0
    private var currentHost: String = ""
    private var currentPort: Int = 0
    private let maxReconnectDelay: TimeInterval = 30.0 // 最大重连延迟时间（秒）
    
    public var onMessage: ((String) -> Void)?
    public var onConnect: (() -> Void)?
    public var onDisconnect: (() -> Void)?
    public var onError: ((Error) -> Void)?
    
    private var messageBuffer: [(message: String, timestamp: TimeInterval)] = []
    private let maxBufferSize = 1000 // 最大缓冲消息数量
    
    public override init() {
        super.init()
    }
    
    public func connect(to host: String, port: Int) {
        currentHost = host
        currentPort = port
        shouldReconnect = true
        reconnectAttempt = 0
        
        guard let url = URL(string: "ws://\(host):\(port)") else {
            onError?(NSError(domain: "WebSocketConnector", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        webSocketTask = session.webSocketTask(with: url)
        
        webSocketTask?.resume()
        receiveMessage()
    }
    
    public func disconnect() {
        shouldReconnect = false
        stopReconnectTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        onDisconnect?()
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func scheduleReconnect() {
        guard shouldReconnect else { return }
        
        stopReconnectTimer()
        
        // 使用指数退避策略计算延迟时间
        let delay = min(pow(2.0, Double(reconnectAttempt)), maxReconnectDelay)
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.reconnectAttempt += 1
            self.connect(to: self.currentHost, port: self.currentPort)
        }
    }
    
    public func send(message: String) {
        // 如果未连接，将消息存入缓冲区
        guard isConnected else {
            addToBuffer(message)
            return
        }
        
        let msg = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(msg) { [weak self] error in
            if let error = error {
                self?.onError?(error)
                // 发送失败时，将消息存入缓冲区
                self?.addToBuffer(message)
            }
        }
    }
    
    private func addToBuffer(_ message: String) {
        let timestamp = Date().timeIntervalSince1970
        messageBuffer.append((message: message, timestamp: timestamp))
        
        // 如果缓冲区超出大小限制，移除最早的消息
        if messageBuffer.count > maxBufferSize {
            messageBuffer.removeFirst()
        }
    }
    
    private func replayBufferedMessages() {
        // 按时间戳排序消息
        let sortedMessages = messageBuffer.sorted { $0.timestamp < $1.timestamp }
        
        // 重发所有缓冲的消息
        for bufferedMessage in sortedMessages {
            let message = URLSessionWebSocketTask.Message.string(bufferedMessage.message)
            webSocketTask?.send(message) { [weak self] error in
                if let error = error {
                    self?.onError?(error)
                }
            }
        }
        
        // 清空缓冲区
        messageBuffer.removeAll()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.onMessage?(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.onMessage?(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                self?.onError?(error)
                if self?.shouldReconnect == true {
                    self?.isConnected = false
                    self?.webSocketTask = nil
                    self?.onDisconnect?()
                    self?.scheduleReconnect()
                } else {
                    self?.disconnect()
                }
            }
        }
    }
}

extension WebSocketConnector: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        onConnect?()
        // 连接成功后重发缓冲消息
        replayBufferedMessages()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        onDisconnect?()
    }
}
