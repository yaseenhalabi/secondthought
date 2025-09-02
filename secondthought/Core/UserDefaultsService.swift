import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

class UserDefaultsService {
    static let shared = UserDefaultsService()
    private let logger = Logger.shared
    
    private init() {}

    private let hasConfiguredAppsKey = "hasConfiguredApps"
    private let selectedAppsKey = "selectedApps"
    private let schemeToTokenMappingKey = "schemeToTokenMapping"
    private let blockedAppTokensKey = "blockedAppTokens"
    private let blockExpirationTimesKey = "blockExpirationTimes"
    private let timingModeKey = "timingMode"
    private let verificationCodeLengthKey = "verificationCodeLength"
    private let selectedAppSchemeKey = "selectedAppScheme"

    private func continueTimestampKey(for scheme: String) -> String {
        return "continueTimestamp_\(scheme)"
    }
    
    var hasConfiguredApps: Bool {
        get { UserDefaults.standard.bool(forKey: hasConfiguredAppsKey) }
        set { 
            UserDefaults.standard.set(newValue, forKey: hasConfiguredAppsKey)
            logger.storage("HasConfiguredApps set to: \(newValue)")
        }
    }
    
    func saveSelectedApps(_ selection: FamilyActivitySelection) {
        guard let encoded = try? JSONEncoder().encode(selection) else {
            logger.error("Failed to encode selected apps")
            return
        }
        UserDefaults.standard.set(encoded, forKey: selectedAppsKey)
        logger.storage("Saved \(selection.applications.count) selected apps")
    }
    
    func loadSelectedApps() -> FamilyActivitySelection? {
        guard let data = UserDefaults.standard.data(forKey: selectedAppsKey),
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
        UserDefaults.standard.set(encoded, forKey: schemeToTokenMappingKey)
        logger.storage("Saved \(mappings.count) mappings")
    }

    func loadMappings() -> [String: ApplicationToken] {
        guard let data = UserDefaults.standard.data(forKey: schemeToTokenMappingKey),
              let decoded = try? JSONDecoder().decode([String: ApplicationToken].self, from: data) else {
            logger.storage("No mappings found")
            return [:]
        }
        logger.storage("Loaded \(decoded.count) mappings")
        return decoded
    }
    
    func saveBlockedTokens(_ tokens: Set<ApplicationToken>) {
        guard let encoded = try? JSONEncoder().encode(Array(tokens)) else {
            logger.error("Failed to encode blocked tokens")
            return
        }
        UserDefaults.standard.set(encoded, forKey: blockedAppTokensKey)
        logger.storage("Saved \(tokens.count) blocked tokens")
    }
    
    func loadBlockedTokens() -> Set<ApplicationToken> {
        guard let data = UserDefaults.standard.data(forKey: blockedAppTokensKey),
              let decoded = try? JSONDecoder().decode([ApplicationToken].self, from: data) else {
            logger.storage("No blocked tokens found")
            return []
        }
        logger.storage("Loaded \(decoded.count) blocked tokens")
        return Set(decoded)
    }
    
    func saveBlockExpirationTimes(_ times: [String: Date]) {
        let expirationData = times.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(expirationData, forKey: blockExpirationTimesKey)
        logger.storage("Saved \(times.count) expiration times")
    }
    
    func loadBlockExpirationTimes() -> [String: Date] {
        guard let savedExpirations = UserDefaults.standard.object(forKey: blockExpirationTimesKey) as? [String: TimeInterval] else {
            logger.storage("No expiration times found")
            return [:]
        }
        let times = savedExpirations.mapValues { Date(timeIntervalSince1970: $0) }
        logger.storage("Loaded \(times.count) expiration times")
        return times
    }
    
    var timingMode: String {
        get { UserDefaults.standard.string(forKey: timingModeKey) ?? "default" }
        set {
            UserDefaults.standard.set(newValue, forKey: timingModeKey)
            logger.storage("Timing mode set to: \(newValue)")
        }
    }
    
    var verificationCodeLength: Int {
        get { 
            let length = UserDefaults.standard.integer(forKey: verificationCodeLengthKey)
            return length > 0 ? length : 4
        }
        set {
            UserDefaults.standard.set(newValue, forKey: verificationCodeLengthKey)
            logger.storage("Code length set to: \(newValue)")
        }
    }
    
    var selectedAppScheme: String {
        get { UserDefaults.standard.string(forKey: selectedAppSchemeKey) ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedAppSchemeKey)
            logger.storage("Selected app scheme set to: '\(newValue)'")
        }
    }
    
    func setContinueTimestamp(_ timestamp: TimeInterval, for scheme: String) {
        let key = continueTimestampKey(for: scheme)
        UserDefaults.standard.set(timestamp, forKey: key)
        logger.storage("Continue timestamp set for \(scheme): \(timestamp)")
    }
    
    func getContinueTimestamp(for scheme: String) -> TimeInterval {
        let key = continueTimestampKey(for: scheme)
        return UserDefaults.standard.double(forKey: key)
    }
    
    func resetConfiguration() {
        logger.storage("Resetting all configuration data")
        
        let keysToRemove = [
            hasConfiguredAppsKey,
            selectedAppsKey,
            schemeToTokenMappingKey,
            blockedAppTokensKey,
            blockExpirationTimesKey
        ]
        
        keysToRemove.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        logger.storage("Configuration reset complete")
    }
}
