import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

class UserDefaultsService {
    static let shared = UserDefaultsService()
    
    private init() {}

    private let hasConfiguredAppsKey = "hasConfiguredApps"
    private let selectedAppsKey = "selectedApps"
    private let schemeToTokenMappingKey = "schemeToTokenMapping"
    private let blockedAppTokensKey = "blockedAppTokens"
    private let blockExpirationTimesKey = "blockExpirationTimes"
    private let selectedAppSchemeKey = "selectedAppScheme"
    private let selectedChallengeNameKey = "selectedChallengeName"

    private func continueTimestampKey(for scheme: String) -> String {
        return "continueTimestamp_\(scheme)"
    }
    
    var hasConfiguredApps: Bool {
        get { UserDefaults.standard.bool(forKey: hasConfiguredAppsKey) }
        set { 
            UserDefaults.standard.set(newValue, forKey: hasConfiguredAppsKey)
        }
    }
    
    func saveSelectedApps(_ selection: FamilyActivitySelection) {
        guard let encoded = try? JSONEncoder().encode(selection) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: selectedAppsKey)
    }
    
    func loadSelectedApps() -> FamilyActivitySelection? {
        guard let data = UserDefaults.standard.data(forKey: selectedAppsKey),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    func saveMappings(_ mappings: [String: ApplicationToken]) {
        guard let encoded = try? JSONEncoder().encode(mappings) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: schemeToTokenMappingKey)
    }

    func loadMappings() -> [String: ApplicationToken] {
        guard let data = UserDefaults.standard.data(forKey: schemeToTokenMappingKey),
              let decoded = try? JSONDecoder().decode([String: ApplicationToken].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    func saveBlockedTokens(_ tokens: Set<ApplicationToken>) {
        guard let encoded = try? JSONEncoder().encode(Array(tokens)) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: blockedAppTokensKey)
    }
    
    func loadBlockedTokens() -> Set<ApplicationToken> {
        guard let data = UserDefaults.standard.data(forKey: blockedAppTokensKey),
              let decoded = try? JSONDecoder().decode([ApplicationToken].self, from: data) else {
            return []
        }
        return Set(decoded)
    }
    
    func saveBlockExpirationTimes(_ times: [String: Date]) {
        let expirationData = times.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(expirationData, forKey: blockExpirationTimesKey)
    }
    
    func loadBlockExpirationTimes() -> [String: Date] {
        guard let savedExpirations = UserDefaults.standard.object(forKey: blockExpirationTimesKey) as? [String: TimeInterval] else {
            return [:]
        }
        let times = savedExpirations.mapValues { Date(timeIntervalSince1970: $0) }
        return times
    }
    
    var selectedChallengeName: String {
        get { UserDefaults.standard.string(forKey: selectedChallengeNameKey) ?? "RandomText" }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedChallengeNameKey)
        }
    }
    
    var selectedAppScheme: String {
        get { UserDefaults.standard.string(forKey: selectedAppSchemeKey) ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedAppSchemeKey)
        }
    }
    
    func setContinueTimestamp(_ timestamp: TimeInterval, for scheme: String) {
        let key = continueTimestampKey(for: scheme)
        UserDefaults.standard.set(timestamp, forKey: key)
    }
    
    func getContinueTimestamp(for scheme: String) -> TimeInterval {
        let key = continueTimestampKey(for: scheme)
        return UserDefaults.standard.double(forKey: key)
    }
    
    func resetConfiguration() {
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
    }
}
