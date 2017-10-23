import Foundation

class DeviceCollector {
    func getDeviceUDID(device : String) -> String {
        // Gets simulator UDID by parsing value between square brackets
        let regex = "\\[(.*?)\\]"
        let match = RegexHandler().matches(for: regex, in: device)
        return match.last ?? ""
    }
}
