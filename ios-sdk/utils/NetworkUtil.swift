import Foundation

public class NetworkUtil {
    private static var requestMap: [String: (Date, URLRequest)] = [:]
    private static var connector: WebSocketConnector? {
        return ConsoleBusIOSSDK.activeSDKInstance?.connector
    }
    
    private static func getRequestBody(from request: URLRequest) -> String? {
        func processData(_ data: Data) -> String {
            if let utf8String = String(data: data, encoding: .utf8) {
                return utf8String
            } else {
                return data.base64EncodedString()
            }
        }
        
        if let httpBody = request.httpBody {
            return processData(httpBody)
        } else if let bodyStream = request.httpBodyStream {
            bodyStream.open()
            defer { bodyStream.close() }
            
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            
            var data = Data()
            repeat {
                let bytesRead = bodyStream.read(buffer, maxLength: bufferSize)
                if bytesRead < 0 {
                    return nil // 读取错误
                } else if bytesRead == 0 {
                    break // 读取完成
                }
                data.append(buffer, count: bytesRead)
            } while true
            
            return processData(data)
        }
        return nil
    }
    
    public static func onNetworkRequest(uniqueId: String, request: URLRequest) {
        requestMap[uniqueId] = (Date(), request)
        
        let proto = ProtoNetwork(
            uniqueId: uniqueId,
            deviceId: DeviceUtil.getDeviceId(),
            msgId: UUID().uuidString,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000),
            requestUri: request.url?.absoluteString ?? "",
            requestHeaders: request.allHTTPHeaderFields ?? [:],
            requestMethod: request.httpMethod ?? "GET",
            requestBody: getRequestBody(from: request),
            responseHeaders: [:],
            responseStatusCode: 0,
            responseBody: nil,
            requestTime: Date(),
            responseTime: Date()
        )
        
        connector?.send(message: proto.toJSONString() ?? "")
    }
    
    public static func onNetworkResponse(uniqueId: String, response: URLResponse?, data: Data?) {
        guard let (requestTime, request) = requestMap[uniqueId],
              let httpResponse = response as? HTTPURLResponse else {
            return
        }
        
        let responseBody = data.map { data -> String in
            if let utf8String = String(data: data, encoding: .utf8) {
                return utf8String
            } else {
                return data.base64EncodedString()
            }
        }
        
        let proto = ProtoNetwork(
            uniqueId: uniqueId,
            deviceId: DeviceUtil.getDeviceId(),
            msgId: UUID().uuidString,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000),
            requestUri: request.url?.absoluteString ?? "",
            requestHeaders: request.allHTTPHeaderFields ?? [:],
            requestMethod: request.httpMethod ?? "GET",
            requestBody: getRequestBody(from: request),
            responseHeaders: httpResponse.allHeaderFields as? [String: String] ?? [:],
            responseStatusCode: httpResponse.statusCode,
            responseBody: responseBody,
            requestTime: requestTime,
            responseTime: Date()
        )
        
        connector?.send(message: proto.toJSONString() ?? "")
        requestMap.removeValue(forKey: uniqueId)
    }
}
