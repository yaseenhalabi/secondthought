import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

class UserDefaultsService {
    static let shared = UserDefaultsService()
    private let logger = Logger.shared
    
    
    private let userDefaults = UserDefaults(suiteName: "group.yaseen.secondthought")!

    private init() {}

    private let hasConfiguredAppsKey = "hasConfiguredApps"
    private let selectedAppsKey = "selectedApps"
    private let schemeToTokenMappingKey = "schemeToTokenMapping"
    private let timingModeKey = "timingMode"
    private let verificationCodeLengthKey = "verificationCodeLength"
    private let selectedAppSchemeKey = "selectedAppScheme"

    private func continueTimestampKey(for scheme: String) -> String {
        return "continueTimestamp_\(scheme)"
    }
    
    var hasConfiguredApps: Bool {
        get { userDefaults.bool(forKey: hasConfiguredAppsKey) }
        set { 
            userDefaults.set(newValue, forKey: hasConfiguredAppsKey)
            logger.storage("HasConfiguredApps set to: \(newValue)")
        }
    }
    
    func saveSelectedApps(_ selection: FamilyActivitySelection) {
        guard let encoded = try? JSONEncoder().encode(selection) else {
            logger.error("Failed to encode selected apps")
            return
        }
        userDefaults.set(encoded, forKey: selectedAppsKey)
        logger.storage("Saved \(selection.applications.count) selected apps")
    }
    
    func loadSelectedApps() -> FamilyActivitySelection? {
        guard let data = userDefaults.data(forKey: selectedAppsKey),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            logger.storage("No saved app selection found")
            return nil
        }
        logger.storage("Loaded \(decoded.applications.count) selected apps")
        return decoded
    }
    
    func saveMappings(_ mappings: [String: ApplicationToken]) {
        guard let encoded = try? JSONEncoder().encode(mappings) else {
            logger.error("Failed to encode mappings")
            return
        }
        userDefaults.set(encoded, forKey: schemeToTokenMappingKey)
        logger.storage("Saved \(mappings.count) mappings")
    }

    func loadMappings() -> [String: ApplicationToken] {
        guard let data = userDefaults.data(forKey: schemeToTokenMappingKey),
              let decoded = try? JSONDecoder().decode([String: ApplicationToken].self, from: data) else {
            logger.storage("No mappings found")
            return [:]
        }
        logger.storage("Loaded \(decoded.count) mappings")
        return decoded
    }
    
    var timingMode: String {
        get { userDefaults.string(forKey: timingModeKey) ?? "default" }
        set {
            userDefaults.set(newValue, forKey: timingModeKey)
            logger.storage("Timing mode set to: \(newValue)")
        }
    }
    
    var verificationCodeLength: Int {
        get { 
            let length = userDefaults.integer(forKey: verificationCodeLengthKey)
            return length > 0 ? length : 4
        }
        set {
            userDefaults.set(newValue, forKey: verificationCodeLengthKey)
            logger.storage("Code length set to: \(newValue)")
        }
    }
    
    var selectedAppScheme: String {
        get { userDefaults.string(forKey: selectedAppSchemeKey) ?? "" }
        set {
            userDefaults.set(newValue, forKey: selectedAppSchemeKey)
            logger.storage("Selected app scheme set to: '\(newValue)'")
        }
    }
    
    func setContinueTimestamp(_ timestamp: TimeInterval, for scheme: String) {
        let key = continueTimestampKey(for: scheme)
        userDefaults.set(timestamp, forKey: key)
        logger.storage("Continue timestamp set for \(scheme): \(timestamp)")
    }
    
    func getContinueTimestamp(for scheme: String) -> TimeInterval {
        let key = continueTimestampKey(for: scheme)
        return userDefaults.double(forKey: key)
    }
    
    func resetConfiguration() {
        logger.storage("Resetting all configuration data")
        
        let keysToRemove = [
            hasConfiguredAppsKey,
            selectedAppsKey,
            schemeToTokenMappingKey,
        ]
        
        keysToRemove.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        
        logger.storage("Configuration reset complete")
    }
}
