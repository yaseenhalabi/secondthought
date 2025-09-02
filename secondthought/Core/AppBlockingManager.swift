import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

class AppBlockingManager {
    static let shared = AppBlockingManager()
    
    private let logger = Logger.shared
    private let storage = UserDefaultsService.shared
    private let tokenMapper = AppTokenMapper.shared
    private let center = DeviceActivityCenter()
    
    private let managedSettings = ManagedSettingsStore(named: .init("SecondThoughtStore"))
    
    private var selectedApps = FamilyActivitySelection()
    
    private init() {
        restoreState()
    }
    
    func initialize(with selectedApps: FamilyActivitySelection) {
        self.selectedApps = selectedApps
        storage.saveSelectedApps(selectedApps)
        logger.info("Initialized with \(selectedApps.applications.count) selected apps", context: "AppBlockingManager")
        startMonitoring()
    }
    
    func restoreState() {
        if let savedApps = storage.loadSelectedApps() {
            selectedApps = savedApps
        }
        logger.info("Restored state: \(selectedApps.applications.count) selected apps", context: "AppBlockingManager")
    }
    
    func startMonitoring() {
        logger.info("Starting device activity monitoring", context: "AppBlockingManager")
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let event = DeviceActivityEvent(
            applications: self.selectedApps.applicationTokens,
            webDomains: self.selectedApps.webDomainTokens,
            threshold: DateComponents(second: 10)
        )
        
        do {
            try center.startMonitoring(.daily, during: schedule, events: [.threshold: event])
            logger.info("Device activity monitoring started successfully", context: "AppBlockingManager")
        } catch {
            logger.error("Error starting device activity monitoring: \(error.localizedDescription)", context: "AppBlockingManager")
        }
    }
    
    func stopMonitoring() {
        logger.info("Stopping device activity monitoring", context: "AppBlockingManager")
        center.stopMonitoring([.daily])
    }
    
    func unblockAllApps() {
        logger.unblocking("Unblocking all apps", context: "AppBlockingManager")
        managedSettings.shield.applications = nil
        managedSettings.shield.webDomains = nil
        stopMonitoring()
    }
    
    func resetConfiguration() {
        logger.info("Resetting configuration", context: "AppBlockingManager")
        unblockAllApps()
        selectedApps = FamilyActivitySelection()
        storage.resetConfiguration()
    }
    
    func validateConfiguration() -> Bool {
        let hasValidApps = !selectedApps.applications.isEmpty
        logger.info("Configuration valid: \(hasValidApps)", context: "AppBlockingManager")
        return hasValidApps
    }
}

// Delegate conformance for older parts of the app, can be removed gradually.
extension AppBlockingManager {
    func blockApp(scheme: String) {
        // This is now handled by the DeviceActivityMonitorExtension
        logger.info("blockApp called for \(scheme), but is now handled by the extension.", context: "AppBlockingManager")
    }
    
    func unblockApp(scheme: String) {
        // Unblocking is handled by removing the shield entirely for a short period.
        // This might be initiated from the ContinueScreen.
        logger.info("unblockApp called for \(scheme).", context: "AppBlockingManager")
        managedSettings.shield.applications = nil
        managedSettings.shield.webDomains = nil
        
        // After a short delay, restart monitoring to re-apply the shield.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.startMonitoring()
        }
    }
    
    func isAppBlocked(scheme: String) -> Bool {
        // This is difficult to determine synchronously now.
        // The UI should adapt to the shield being active rather than checking a boolean.
        return false
    }
    
    func unblockExpiredApp(scheme: String) {
        // Not relevant anymore with the new model.
    }
    
    func startMonitoring(for urlScheme: String, timingMode: TimingMode, customDelay: Double? = nil) {
        // This is now handled by the DeviceActivityMonitorExtension
        logger.info("startMonitoring called for \(urlScheme), but is now handled by the extension.", context: "AppBlockingManager")
    }
    
    func unblockAppForScheme(_ urlScheme: String) {
        unblockApp(scheme: urlScheme)
    }
}

