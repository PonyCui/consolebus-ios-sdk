//
//  ProtoNetwork.swift
//  ios-sdk
//
//  Created by PonyCui on 2025/1/30.
//

import Foundation

public class ProtoNetwork: ProtoMessageBase {
    public let uniqueId: String
    public let requestUri: String
    public let requestHeaders: [String: String]
    public let requestMethod: String
    public let requestBody: String?
    public let responseHeaders: [String: String]
    public let responseStatusCode: Int
    public let responseBody: String?
    public let requestTime: Date
    public let responseTime: Date
    
    public init(
        uniqueId: String,
        deviceId: String,
        msgId: String,
        createdAt: Int64,
        requestUri: String,
        requestHeaders: [String: String],
        requestMethod: String,
        requestBody: String?,
        responseHeaders: [String: String],
        responseStatusCode: Int,
        responseBody: String?,
        requestTime: Date,
        responseTime: Date
    ) {
        self.uniqueId = uniqueId
        self.requestUri = requestUri
        self.requestHeaders = requestHeaders
        self.requestMethod = requestMethod
        self.requestBody = requestBody
        self.responseHeaders = responseHeaders
        self.responseStatusCode = responseStatusCode
        self.responseBody = responseBody
        self.requestTime = requestTime
        self.responseTime = responseTime
        super.init(deviceId: deviceId, msgId: msgId, featureId: "network", createdAt: createdAt)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override public var description: String {
        return "\(requestMethod) \(requestUri)"
    }
    
    public override func toJson() -> [String: Any] {
        var json = super.toJson()
        json["uniqueId"] = uniqueId
        json["requestUri"] = requestUri
        json["requestHeaders"] = requestHeaders
        json["requestMethod"] = requestMethod
        json["requestBody"] = requestBody
        json["responseHeaders"] = responseHeaders
        json["responseStatusCode"] = responseStatusCode
        json["responseBody"] = responseBody
        json["requestTime"] = Int64(requestTime.timeIntervalSince1970 * 1000)
        json["responseTime"] = Int64(responseTime.timeIntervalSince1970 * 1000)
        return json
    }
    
    public static func fromJSON(_ json: [String: Any]) -> ProtoNetwork? {
        guard let uniqueId = json["uniqueId"] as? String,
              let deviceId = json["deviceId"] as? String,
              let msgId = json["msgId"] as? String,
              let createdAt = json["createdAt"] as? Int64,
              let requestUri = json["requestUri"] as? String,
              let requestHeaders = json["requestHeaders"] as? [String: String],
              let requestMethod = json["requestMethod"] as? String,
              let responseHeaders = json["responseHeaders"] as? [String: String],
              let responseStatusCode = json["responseStatusCode"] as? Int,
              let requestTime = json["requestTime"] as? Int64,
              let responseTime = json["responseTime"] as? Int64 else {
            return nil
        }
        
        return ProtoNetwork(
            uniqueId: uniqueId,
            deviceId: deviceId,
            msgId: msgId,
            createdAt: createdAt,
            requestUri: requestUri,
            requestHeaders: requestHeaders,
            requestMethod: requestMethod,
            requestBody: json["requestBody"] as? String,
            responseHeaders: responseHeaders,
            responseStatusCode: responseStatusCode,
            responseBody: json["responseBody"] as? String,
            requestTime: Date(timeIntervalSince1970: TimeInterval(requestTime) / 1000),
            responseTime: Date(timeIntervalSince1970: TimeInterval(responseTime) / 1000)
        )
    }
}
