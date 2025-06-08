import Foundation

public protocol FeatureHandler {
    func featureIdentifier() -> String
    func handleMessage(_ message: ProtoMessageBase, from connector: MessageConnector)
}
