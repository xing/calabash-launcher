import Foundation

enum Constants {
    enum Strings {
        static let noDevicesConnected = "There are no connected devices.".localized
        static let noSimulatorsConnected = "There are no connected simulators.".localized
        static let pluginDevice = "Please plug-in your device.".localized
        static let installSimulator = "Please install an iOS simulator.".localized
        static let installSimulatorOrPluginDevice = "Please install a simulator or plug-in your device.".localized
        static let useLocalBuild = "Skipping download. Use a local app version.".localized
        static let notCompatibleWithDeviceType = "not compatible with chosen device type.".localized
        static let wrongDeviceSetup = "Please provide the device IP and bundle identifier of your application. It can be configured under 'Configure Device' settings.".localized
    }

    enum Keys {
        static let linkInfo = "linksInfo"
        static let cucumberProfileInfo = "cucumberProfileInfo"
        static let cucumberProfileField = "cucumberProfileField"
        static let additionalFieldInfo = "additionalInfo"
        static let additionalDataField = "additionalDataField"
        static let pathToBuildInfo = "pathToBuildInfo"
        static let commandFieldInfo = "commandFieldInfo"
    }
    
    enum FilePaths {
        private static let main = Bundle.main
        enum Bash {
            static let startDevice = main.path(forResource: "start_device", ofType: .bash)
            static let buildScript = main.path(forResource: "BuildScript", ofType: .bash)
            static let killProcess = main.path(forResource: "kill_process", ofType: .bash)
            static let flash = main.path(forResource: "flash", ofType: .bash)
            static let appDownload = main.path(forResource: "app_download", ofType: .bash)
            static let checkSimulatorType = main.path(forResource: "check_sim_type", ofType: .bash)
            
            // Interactive Ruby Shell
            static let createIRBSession = main.path(forResource: "create_irb_session", ofType: .bash)
            static let sendToIRB = main.path(forResource: "send_to_irb", ofType: .bash)
            static let quitIRBSession = main.path(forResource: "quit_irb_session", ofType: .bash)
            
            // Getters
            static let tags = main.path(forResource: "get_tags", ofType: .bash)
            static let elements = main.path(forResource: "get_elements", ofType: .bash)
            static let elementsByOffset = main.path(forResource: "get_elements_by_offset", ofType: .bash)
            static let screen = main.path(forResource: "get_screen", ofType: .bash)
            static let changeLanguage = main.path(forResource: "change_sim_language", ofType: .bash)
            static let uniqueElements = main.path(forResource: "get_uniq_elements", ofType: .bash)
            static let simulators = main.path(forResource: "get_sim_list", ofType: .bash)
            static let physicalDevices = main.path(forResource: "get_physical_device", ofType: .bash)
        }
        enum Ruby {
            static let helpers = main.path(forResource: "helpers", ofType: .ruby)
        }
    }
    
    enum DeviceType {
        case simulator
        case physical
    }
    
    enum CalabashData {
        static let port = "37265"
    }
}
