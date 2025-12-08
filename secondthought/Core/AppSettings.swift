import Foundation
import SwiftUI
import Combine
import FamilyControls
import ManagedSettings

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // Keys
    private let hasConfiguredAppsKey = "hasConfiguredApps"
    private let selectedAppsKey = "selectedApps"
    private let schemeToTokenMappingKey = "schemeToTokenMapping"
    private let selectedAppSchemeKey = "selectedAppScheme"
    private let selectedChallengeNameKey = "selectedChallengeName"

    private func continueTimestampKey(for scheme: String) -> String {
        return "continueTimestamp_\(scheme)"
    }
    
    @Published var hasConfiguredApps: Bool {
        didSet {
            UserDefaults.standard.set(hasConfiguredApps, forKey: hasConfiguredAppsKey)
        }
    }
    
    private init() {
        self.hasConfiguredApps = UserDefaults.standard.bool(forKey: hasConfiguredAppsKey)
    }
    
    // MARK: - Selected Apps
    
    func saveSelectedApps(_ selection: FamilyActivitySelection) {
        guard let encoded = try? JSONEncoder().encode(selection) else { return }
        UserDefaults.standard.set(encoded, forKey: selectedAppsKey)
    }
    
    func loadSelectedApps() -> FamilyActivitySelection? {
        guard let data = UserDefaults.standard.data(forKey: selectedAppsKey),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    // MARK: - App Token Mappings
    
    func saveMappings(_ mappings: [String: ApplicationToken]) {
        guard let encoded = try? JSONEncoder().encode(mappings) else { return }
        UserDefaults.standard.set(encoded, forKey: schemeToTokenMappingKey)
    }

    func loadMappings() -> [String: ApplicationToken] {
        guard let data = UserDefaults.standard.data(forKey: schemeToTokenMappingKey),
              let decoded = try? JSONDecoder().decode([String: ApplicationToken].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    // MARK: - Selection State
    
    var selectedChallengeName: String {
        get { UserDefaults.standard.string(forKey: selectedChallengeNameKey) ?? "RandomText" }
        set { UserDefaults.standard.set(newValue, forKey: selectedChallengeNameKey) }
    }
    
    var selectedAppScheme: String {
        get { UserDefaults.standard.string(forKey: selectedAppSchemeKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: selectedAppSchemeKey) }
    }
    
    func clearSelectedAppScheme() {
        selectedAppScheme = ""
    }
    
    // MARK: - Timestamps & Logic
    
    func setContinueTimestamp(for scheme: String) {
        let now = Date().timeIntervalSince1970
        let key = continueTimestampKey(for: scheme)
        UserDefaults.standard.set(now, forKey: key)
    }
    
    func getContinueTimestamp(for scheme: String) -> TimeInterval {
        let key = continueTimestampKey(for: scheme)
        return UserDefaults.standard.double(forKey: key)
    }
    
    func shouldSkipForegrounding(for scheme: String) -> Bool {
        let lastContinueTime = getContinueTimestamp(for: scheme)
        let timeSinceContinue = Date().timeIntervalSince1970 - lastContinueTime
        let continueCooldownPeriod: Double = 30
        
        return lastContinueTime > 0 && timeSinceContinue < continueCooldownPeriod
    }
    
    // MARK: - Reset
    
    func resetConfiguration() {
        let keysToRemove = [
            hasConfiguredAppsKey,
            selectedAppsKey,
            schemeToTokenMappingKey
        ]
        
        keysToRemove.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        hasConfiguredApps = false
    }
}
