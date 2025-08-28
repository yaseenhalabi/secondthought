import Foundation
import FamilyControls
import ManagedSettings

class AppBlockingManager: AppBlockingManagerDelegate {
    static let shared = AppBlockingManager()
    
    private let logger = Logger.shared
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
        logger.info("Initialized with \(selectedApps.applications.count) selected apps", context: "AppBlockingManager")
    }
    
    func restoreState() {
        blockedApps = storage.loadBlockedTokens()
        if let savedApps = storage.loadSelectedApps() {
            selectedApps = savedApps
        }
        
        updateShieldSettings()
        timerManager.restoreState()
        
        logger.info("Restored state: \(blockedApps.count) blocked apps", context: "AppBlockingManager")
    }
    
    func unblockAppForScheme(_ urlScheme: String) {
        logger.unblocking("Unblocking app for scheme: \(urlScheme)", context: "AppBlockingManager")
        
        guard let token = tokenMapper.getToken(for: urlScheme, from: selectedApps) else {
            logger.error("No token found for scheme: \(urlScheme)", context: "AppBlockingManager")
            return
        }
        
        let wasRemoved = blockedApps.remove(token) != nil
        logger.unblocking("Token removed from blocked apps: \(wasRemoved)", context: "AppBlockingManager")
        
        if wasRemoved {
            updateShieldSettings()
            saveState()
        }
    }
    
    func startMonitoring(for urlScheme: String, timingMode: TimingMode, customDelay: Double? = nil) {
        guard tokenMapper.getToken(for: urlScheme, from: selectedApps) != nil else {
            logger.error("Cannot start monitoring - no token for \(urlScheme)", context: "AppBlockingManager")
            return
        }
        
        logger.info("Starting monitoring for \(urlScheme)", context: "AppBlockingManager")
        timerManager.startMonitoring(for: urlScheme, timingMode: timingMode, customDelay: customDelay)
    }
    
    private func updateShieldSettings() {
        logger.shield("Updating shield with \(blockedApps.count) blocked apps", context: "AppBlockingManager")
        
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        guard authStatus == .approved else {
            logger.error("Not authorized for Family Controls (status: \(authStatus))", context: "AppBlockingManager")
            return
        }
        
        let shieldValue = blockedApps.isEmpty ? nil : blockedApps
        managedSettings.shield.applications = shieldValue
        
        logger.shield("Shield updated successfully", context: "AppBlockingManager")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            let currentCount = self?.managedSettings.shield.applications?.count ?? 0
            self?.logger.shield("Verification: Shield contains \(currentCount) apps", context: "AppBlockingManager")
        }
    }
    
    private func saveState() {
        storage.saveBlockedTokens(blockedApps)
        tokenMapper.updateActiveMappings(tokenMapper.getLearnedMappings())
    }
    
    func isAppBlocked(scheme: String) -> Bool {
        guard let token = tokenMapper.getToken(for: scheme, from: selectedApps) else {
            return false
        }
        return blockedApps.contains(token)
    }
    
    func unblockAllApps() {
        logger.unblocking("Unblocking all apps", context: "AppBlockingManager")
        blockedApps.removeAll()
        timerManager.cancelAllTimers()
        updateShieldSettings()
        saveState()
    }
    
    func resetConfiguration() {
        logger.info("Resetting configuration", context: "AppBlockingManager")
        unblockAllApps()
        selectedApps = FamilyActivitySelection()
        tokenMapper.loadMappings()
        storage.resetConfiguration()
    }
    
    func validateConfiguration() -> Bool {
        let hasValidApps = !selectedApps.applications.isEmpty
        logger.info("Configuration valid: \(hasValidApps)", context: "AppBlockingManager")
        return hasValidApps
    }
}

extension AppBlockingManager {
    func blockApp(scheme: String) {
        logger.blocking("Blocking app for scheme: \(scheme)", context: "AppBlockingManager")
        
        guard let token = tokenMapper.getToken(for: scheme, from: selectedApps) else {
            logger.error("Cannot block - no token for \(scheme)", context: "AppBlockingManager")
            return
        }
        
        let wasInserted = blockedApps.insert(token).inserted
        logger.blocking("Token added to blocked apps: \(wasInserted)", context: "AppBlockingManager")
        
        if wasInserted {
            updateShieldSettings()
            saveState()
        }
    }
    
    func unblockApp(scheme: String) {
        logger.unblocking("Unblocking app for scheme: \(scheme)", context: "AppBlockingManager")
        
        guard let token = tokenMapper.getToken(for: scheme, from: selectedApps) else {
            logger.error("Cannot unblock - no token for \(scheme)", context: "AppBlockingManager")
            return
        }
        
        blockedApps.remove(token)
        updateShieldSettings()
        saveState()
    }
    
    func unblockExpiredApp(scheme: String) {
        logger.unblocking("Unblocking expired app for scheme: \(scheme)", context: "AppBlockingManager")
        unblockApp(scheme: scheme)
    }
}
