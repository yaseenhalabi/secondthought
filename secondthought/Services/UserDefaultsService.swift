import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

class UserDefaultsService {
    static let shared = UserDefaultsService()
    private let logger = Logger.shared
    
    private init() {}
    
    private enum Keys {
        static let hasConfiguredApps = "hasConfiguredApps"
        static let selectedApps = "selectedApps"
        static let learnedSchemeToTokenMapping = "learnedSchemeToTokenMapping"
        static let activeSchemeToTokenMapping = "activeSchemeToTokenMapping"
        static let blockedAppTokens = "blockedAppTokens"
        static let blockExpirationTimes = "blockExpirationTimes"
        static let timingMode = "timingMode"
        static let verificationCodeLength = "verificationCodeLength"
        static let selectedAppScheme = "selectedAppScheme"
        
        static func continueTimestamp(for scheme: String) -> String {
            return "continueTimestamp_\(scheme)"
        }
    }
    
    var hasConfiguredApps: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasConfiguredApps) }
        set { 
            UserDefaults.standard.set(newValue, forKey: Keys.hasConfiguredApps)
            logger.storage("HasConfiguredApps set to: \(newValue)")
        }
    }
    
    func saveSelectedApps(_ selection: FamilyActivitySelection) {
        guard let encoded = try? JSONEncoder().encode(selection) else {
            logger.error("Failed to encode selected apps")
            return
        }
        UserDefaults.standard.set(encoded, forKey: Keys.selectedApps)
        logger.storage("Saved \(selection.applications.count) selected apps")
    }
    
    func loadSelectedApps() -> FamilyActivitySelection? {
        guard let data = UserDefaults.standard.data(forKey: Keys.selectedApps),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            logger.storage("No saved app selection found")
            return nil
        }
        logger.storage("Loaded \(decoded.applications.count) selected apps")
        return decoded
    }
    
    func saveLearnedMappings(_ mappings: [String: ApplicationToken]) {
        guard let encoded = try? JSONEncoder().encode(mappings) else {
            logger.error("Failed to encode learned mappings")
            return
        }
        UserDefaults.standard.set(encoded, forKey: Keys.learnedSchemeToTokenMapping)
        logger.storage("Saved \(mappings.count) learned mappings")
    }
    
    func loadLearnedMappings() -> [String: ApplicationToken] {
        guard let data = UserDefaults.standard.data(forKey: Keys.learnedSchemeToTokenMapping),
              let decoded = try? JSONDecoder().decode([String: ApplicationToken].self, from: data) else {
            
            if let altData = UserDefaults.standard.data(forKey: Keys.activeSchemeToTokenMapping),
               let altDecoded = try? JSONDecoder().decode([String: ApplicationToken].self, from: altData) {
                logger.storage("Loaded \(altDecoded.count) mappings from alternative key")
                return altDecoded
            }
            
            logger.storage("No learned mappings found")
            return [:]
        }
        logger.storage("Loaded \(decoded.count) learned mappings")
        return decoded
    }
    
    func saveActiveMappings(_ mappings: [String: ApplicationToken]) {
        guard let encoded = try? JSONEncoder().encode(mappings) else {
            logger.error("Failed to encode active mappings")
            return
        }
        UserDefaults.standard.set(encoded, forKey: Keys.activeSchemeToTokenMapping)
        logger.storage("Saved \(mappings.count) active mappings")
    }
    
    func loadActiveMappings() -> [String: ApplicationToken] {
        guard let data = UserDefaults.standard.data(forKey: Keys.activeSchemeToTokenMapping),
              let decoded = try? JSONDecoder().decode([String: ApplicationToken].self, from: data) else {
            logger.storage("No active mappings found")
            return [:]
        }
        logger.storage("Loaded \(decoded.count) active mappings") 
        return decoded
    }
    
    func saveBlockedTokens(_ tokens: Set<ApplicationToken>) {
        guard let encoded = try? JSONEncoder().encode(Array(tokens)) else {
            logger.error("Failed to encode blocked tokens")
            return
        }
        UserDefaults.standard.set(encoded, forKey: Keys.blockedAppTokens)
        logger.storage("Saved \(tokens.count) blocked tokens")
    }
    
    func loadBlockedTokens() -> Set<ApplicationToken> {
        guard let data = UserDefaults.standard.data(forKey: Keys.blockedAppTokens),
              let decoded = try? JSONDecoder().decode([ApplicationToken].self, from: data) else {
            logger.storage("No blocked tokens found")
            return []
        }
        logger.storage("Loaded \(decoded.count) blocked tokens")
        return Set(decoded)
    }
    
    func saveBlockExpirationTimes(_ times: [String: Date]) {
        let expirationData = times.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(expirationData, forKey: Keys.blockExpirationTimes)
        logger.storage("Saved \(times.count) expiration times")
    }
    
    func loadBlockExpirationTimes() -> [String: Date] {
        guard let savedExpirations = UserDefaults.standard.object(forKey: Keys.blockExpirationTimes) as? [String: TimeInterval] else {
            logger.storage("No expiration times found")
            return [:]
        }
        let times = savedExpirations.mapValues { Date(timeIntervalSince1970: $0) }
        logger.storage("Loaded \(times.count) expiration times")
        return times
    }
    
    var timingMode: String {
        get { UserDefaults.standard.string(forKey: Keys.timingMode) ?? "default" }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.timingMode)
            logger.storage("Timing mode set to: \(newValue)")
        }
    }
    
    var verificationCodeLength: Int {
        get { 
            let length = UserDefaults.standard.integer(forKey: Keys.verificationCodeLength)
            return length > 0 ? length : 4
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.verificationCodeLength)
            logger.storage("Code length set to: \(newValue)")
        }
    }
    
    var selectedAppScheme: String {
        get { UserDefaults.standard.string(forKey: Keys.selectedAppScheme) ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.selectedAppScheme)
            logger.storage("Selected app scheme set to: '\(newValue)'")
        }
    }
    
    func setContinueTimestamp(_ timestamp: TimeInterval, for scheme: String) {
        let key = Keys.continueTimestamp(for: scheme)
        UserDefaults.standard.set(timestamp, forKey: key)
        logger.storage("Continue timestamp set for \(scheme): \(timestamp)")
    }
    
    func getContinueTimestamp(for scheme: String) -> TimeInterval {
        let key = Keys.continueTimestamp(for: scheme)
        return UserDefaults.standard.double(forKey: key)
    }
    
    func resetConfiguration() {
        logger.storage("Resetting all configuration data")
        
        let keysToRemove = [
            Keys.hasConfiguredApps,
            Keys.selectedApps,
            Keys.learnedSchemeToTokenMapping,
            Keys.activeSchemeToTokenMapping,
            Keys.blockedAppTokens,
            Keys.blockExpirationTimes
        ]
        
        keysToRemove.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        logger.storage("Configuration reset complete")
    }
}
