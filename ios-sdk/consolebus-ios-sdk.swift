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
            self?.syncPreference()
        }
        connector?.onMessage = { [weak self] (msgString) in
            if let msgUtf8Data = msgString.data(using: .utf8),
               let msgObject = try? JSONSerialization.jsonObject(with: msgUtf8Data) as? [String: Any] {
                let msg = ProtocolMessageFactory.fromJSON(msgObject)
                if let msg, msg.deviceId != DeviceUtil.getDeviceId() {
                    return
                }
                if let msg = msg as? ProtoPreference, msg.operation == "set" {
                    self?.onPreferenceSet(msg)
                } else if let msg = msg as? ProtoPreference, msg.operation == "sync" {
                    self?.syncPreference()
                }
            }
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
    
    private func syncPreference() {
        PreferenceAdapter.currentPreferenceAdapter?.getAll()
    }
    
    private func onPreferenceSet(_ message: ProtoPreference) {
        PreferenceAdapter.currentPreferenceAdapter?.setValue(key: message.key,
                                                             value: message.value)
    }
    
    public func stop() {
        connector?.disconnect()
        connector = nil
        ConsoleBusIOSSDK.activeSDKInstance = nil
    }
}
