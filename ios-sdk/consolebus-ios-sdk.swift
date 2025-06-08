//
//  consolebus-ios-sdk.swift
//  ios-sdk
//
//  Created by PonyCui on 2025/1/30.
//

import Foundation

public class ConnectorConfig {
    public init() {}
}

public class WebSocketConnectorConfig: ConnectorConfig {
    public let host: String
    public let port: Int
    
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
        super.init()
    }
}

public class LocalFileConnectorConfig: ConnectorConfig {
    public let filename: String?
    
    public init(filename: String?) {
        self.filename = filename
        super.init()
    }
}

public class ConsoleBusIOSSDK {
    
    static public private(set) var activeSDKInstance: ConsoleBusIOSSDK? = nil
    
    let connectorConfig: ConnectorConfig
    var connector: MessageConnector?
    private var featureHandlers: [String: FeatureHandler] = [:]
    
    public init(connectorConfig: ConnectorConfig) {
        self.connectorConfig = connectorConfig
    }
    
    public func start() {
        ConsoleBusIOSSDK.activeSDKInstance = self
        self.registerInitialFeatureHandlers()
        
        if let wsConfig = connectorConfig as? WebSocketConnectorConfig {
            let wsConnector = WebSocketConnector()
            wsConnector.onConnect = { [weak self] in
                self?.sendDeviceInfo()
                self?.syncPreference()
            }
            wsConnector.onMessage = { [weak self] (msgString) in
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
                    } else if let msg, let handler = self?.featureHandlers[msg.featureId] {
                        handler.handleMessage(msg, from: self!.connector!)
                    } else {
                        print("No handler registered for featureId: \(msg?.featureId)")
                    }
                }
            }
            wsConnector.connect(to: wsConfig.host, port: wsConfig.port)
            connector = wsConnector
        } else if let fileConfig = connectorConfig as? LocalFileConnectorConfig {
            let fileConnector = LocalFileConnector(filename: fileConfig.filename)
            connector = fileConnector
            DispatchQueue.main.async {
                self.sendDeviceInfo()
                self.syncPreference()
            }
        }
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
    
    public func registerFeatureHandler(handler: FeatureHandler) {
        featureHandlers[handler.featureIdentifier()] = handler
        print("Registered feature handler for: \(handler.featureIdentifier())")
    }

    private func registerInitialFeatureHandlers() {
        // Register core feature handlers here if any, or allow them to be registered externally.
        // For now, FilesystemFeatureHandler will be registered after SDK initialization as an example.
        // If you have handlers that should always be present, register them here.
        // Example: registerFeatureHandler(handler: SomeCoreFeatureHandler())
        let fsHandler = FilesystemFeatureHandler()
        registerFeatureHandler(handler: fsHandler)
    }
    
    public func stop() {
        connector?.stop()
        connector = nil
        ConsoleBusIOSSDK.activeSDKInstance = nil
    }
}
