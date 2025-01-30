import Foundation
import UIKit

public class DeviceUtil {
    public static func getDeviceName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceModel = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let deviceName = UIDevice.current.name
        return "\(deviceName) (\(deviceModel))"
    }

    public static func getDeviceType() -> String {
        return "iOS"
    }
    
    public static func getDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}