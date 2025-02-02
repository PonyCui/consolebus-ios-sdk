import Foundation

public class NetworkURLSessionAdapter: URLProtocol {
    
    private static let operationQueue = OperationQueue()
    
    private static let uniqueIdKey = "NetworkAdapterUniqueId"
    
    public static func register() {
        operationQueue.maxConcurrentOperationCount = 1
        URLProtocol.registerClass(self)
    }
    
    public static func unregister() {
        URLProtocol.unregisterClass(self)
    }
    
    private let uniqueId = UUID().uuidString
    
    public override class func canInit(with request: URLRequest) -> Bool {
        // 避免重复处理同一请求
        if URLProtocol.property(forKey: uniqueIdKey, in: request) != nil {
            return false
        }
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        guard client != nil else { return }
        
        // 标记请求已被处理
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(uniqueId, forKey: NetworkURLSessionAdapter.uniqueIdKey, in: mutableRequest)
        
        // 发送请求信息
        NetworkURLSessionAdapter.operationQueue.addOperation {
            NetworkUtil.onNetworkRequest(uniqueId: self.uniqueId, request: self.request)
        }
        
        // 创建新的 URLSession 发送请求
        let config = URLSessionConfiguration.default
        config.protocolClasses = nil // 避免递归
        let session = URLSession(configuration: config)
        
        let dataTask = session.dataTask(with: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                NetworkURLSessionAdapter.operationQueue.addOperation {
                    NetworkUtil.onNetworkError(uniqueId: self.uniqueId,
                                               request: self.request,
                                               error: error)
                }
                return
            }
            
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
                // 发送响应信息
                NetworkURLSessionAdapter.operationQueue.addOperation {
                    NetworkUtil.onNetworkResponse(uniqueId: self.uniqueId,
                                                  response: response,
                                                  data: data)
                }
            }
            
            self.client?.urlProtocolDidFinishLoading(self)
        }
        
        dataTask.resume()
    }
    
    public override func stopLoading() {
        NetworkURLSessionAdapter.operationQueue.addOperation {
            NetworkUtil.onNetworkCancel(uniqueId: self.uniqueId, request: self.request)
        }
    }
}
