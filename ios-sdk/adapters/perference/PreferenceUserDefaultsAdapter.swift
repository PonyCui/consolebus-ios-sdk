import Foundation

public class PreferenceUserDefaultsAdapter: PreferenceAdapter {
    
    public static func register() {
        PreferenceAdapter.currentPreferenceAdapter = PreferenceUserDefaultsAdapter()
    }
    
    public static func unregister() {
        PreferenceAdapter.currentPreferenceAdapter = nil
    }
    
    private var connector: MessageConnector? {
        return ConsoleBusIOSSDK.activeSDKInstance?.connector
    }
    
    public override func getAll() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        for (key, value) in dictionary {
            PreferenceUtil.onGetKeyValue(key: key, value: fotmatValue(value))
        }
    }
    
    public override func setValue(key: String, value: Any) {
        let defaults = UserDefaults.standard
        let formattedValue = fotmatValue(value)
        defaults.set(formattedValue, forKey: key)
        defaults.synchronize()
        PreferenceUtil.onGetKeyValue(key: key, value: formattedValue)
    }
    
    private func fotmatValue(_ value: Any) -> Any {
        switch value {
        case let number as NSNumber:
            return number
        case let string as String:
            return string
        case let array as [Any]:
            return array.map { fotmatValue($0) }
        case let dictionary as [String: Any]:
            var jsonDict = [String: Any]()
            for (key, val) in dictionary {
                jsonDict[key] = fotmatValue(val)
            }
            return jsonDict
        case let date as Date:
            return Int64(date.timeIntervalSince1970 * 1000)
        case let url as URL:
            return url.absoluteString
        default:
            return String(describing: value)
        }
    }
}
