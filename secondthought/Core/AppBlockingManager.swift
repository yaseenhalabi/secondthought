import Foundation
import FamilyControls
import ManagedSettings

class AppBlockingManager: AppBlockingManagerDelegate {
    static let shared = AppBlockingManager()
    
    private let storage = UserDefaultsService.shared
    private let tokenMapper = AppTokenMapper.shared
    private let timerManager = TimerManager.shared
    
    private let managedSettings = ManagedSettingsStore(named: .init("SecondThoughtStore"))
    
    private var blockedApps: Set<ApplicationToken> = []
    private var selectedApps = FamilyActivitySelection()
    
    private init() {
        timerManager.blockingDelegate = self
        restoreState()
    }
    
    func initialize(with selectedApps: FamilyActivitySelection) {
        self.selectedApps = selectedApps
    }
    
    func restoreState() {
        blockedApps = storage.loadBlockedTokens()
        if let savedApps = storage.loadSelectedApps() {
            selectedApps = savedApps
        }
        
        updateShieldSettings()
        timerManager.restoreState()
    }
    
    func unblockAppForScheme(_ urlScheme: String) {
        unblockApp(scheme: urlScheme)
    }
    
    func startMonitoring(for urlScheme: String, timingMode: TimingMode, customDelay: Double? = nil) {
        guard tokenMapper.getToken(for: urlScheme, from: selectedApps) != nil else {
            return
        }
        
        timerManager.startMonitoring(for: urlScheme, timingMode: timingMode, customDelay: customDelay)
    }
    
    private func updateShieldSettings() {
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        guard authStatus == .approved else {
            return
        }
        
        let shieldValue = blockedApps.isEmpty ? nil : blockedApps
        managedSettings.shield.applications = shieldValue
    }
    
    private func saveState() {
        storage.saveBlockedTokens(blockedApps)
    }
    
    func isAppBlocked(scheme: String) -> Bool {
        guard let token = tokenMapper.getToken(for: scheme, from: selectedApps) else {
            return false
        }
        return blockedApps.contains(token)
    }
    
    func unblockAllApps() {
        blockedApps.removeAll()
        timerManager.cancelAllTimers()
        updateShieldSettings()
        saveState()
    }
    
    func resetConfiguration() {
        unblockAllApps()
        selectedApps = FamilyActivitySelection()
        tokenMapper.loadMappings()
        storage.resetConfiguration()
    }
    
    func validateConfiguration() -> Bool {
        let hasValidApps = !selectedApps.applications.isEmpty
        return hasValidApps
    }
}

extension AppBlockingManager {
    func blockApp(scheme: String) {
        guard let token = tokenMapper.getToken(for: scheme, from: selectedApps) else {
            return
        }
        
        let wasInserted = blockedApps.insert(token).inserted
        
        if wasInserted {
            updateShieldSettings()
            saveState()
        }
    }
    
    func unblockApp(scheme: String) {
        guard let token = tokenMapper.getToken(for: scheme, from: selectedApps) else {
            return
        }
        
        let wasRemoved = blockedApps.remove(token) != nil
        
        if wasRemoved {
            updateShieldSettings()
            saveState()
        }
    }
    
    func unblockExpiredApp(scheme: String) {
        unblockApp(scheme: scheme)
    }
}
