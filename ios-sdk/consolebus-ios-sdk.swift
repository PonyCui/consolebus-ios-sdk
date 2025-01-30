//
//  consolebus-ios-sdk.swift
//  ios-sdk
//
//  Created by PonyCui on 2025/1/30.
//

import Foundation

public class ConsoleBusConfig {
    public let host: String
    public let port: Int
    
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
}

public class ConsoleBusIOSSDK {
    
    static public private(set) var activeSDKInstance: ConsoleBusIOSSDK? = nil
    
    let config: ConsoleBusConfig
    var connector: WebSocketConnector?
    
    public init(config: ConsoleBusConfig) {
        self.config = config
    }
    
    public func start() {
        ConsoleBusIOSSDK.activeSDKInstance = self
        connector = WebSocketConnector()
        connector?.onConnect = { [weak self] in
            self?.sendDeviceInfo()
        }
        connector?.connect(to: config.host, port: config.port)
    }
    
    private func sendDeviceInfo() {
        let deviceId = DeviceUtil.getDeviceId()
        let deviceName = DeviceUtil.getDeviceName()
        let deviceType = DeviceUtil.getDeviceType()
        let msgId = UUID().uuidString
        let createdAt = Int64(Date().timeIntervalSince1970 * 1000)
        
        let deviceInfo = ProtoDevice(
            deviceName: deviceName,
            deviceType: deviceType,
            deviceId: deviceId,
            msgId: msgId,
            createdAt: createdAt
        )
        
        connector?.send(message: deviceInfo.toJSONString() ?? "")
    }
    
    public func stop() {
        connector?.disconnect()
        connector = nil
        ConsoleBusIOSSDK.activeSDKInstance = nil
    }
}
