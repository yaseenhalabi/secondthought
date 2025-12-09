import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

extension DeviceActivityName {
    static let blockingSchedule = DeviceActivityName("secondthought.blocking.schedule")
    static let blockingEvent = DeviceActivityName("secondthought.blocking.event.monitor")
}

class AppBlockingManager {
    static let shared = AppBlockingManager()
    
    private let settings = AppSettings.shared
    private let tokenMapper = AppTokenMapper.shared
    
    private var selectedApps = FamilyActivitySelection()
    
    private init() {
        restoreState()
    }
    
    func unblockAllApps() {
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    func startBlockingIntervalForAllApps(duration: TimeInterval) {
        let center = DeviceActivityCenter()

        // Use the provided duration as the threshold for a DeviceActivityEvent
        // Convert the provided duration (seconds) into DateComponents for the threshold
        let totalSeconds = Int(duration.rounded())
        var threshold = DateComponents()
        threshold.second = totalSeconds

        // Event name to identify our single threshold-based event
        let eventName = DeviceActivityEvent.Name("secondthought.blocking.event")

        // Build an event that applies broadly (no specific apps/categories/web domains).
        // Use empty sets instead of nil to satisfy the API.
        let event = DeviceActivityEvent(
            applications: [],
            categories: [],
            webDomains: [],
            threshold: threshold
        )

        // Provide a minimal schedule window that starts now and ends after the threshold.
        // DeviceActivity APIs require a schedule (DateComponents), even when using events.
        let now = Date()
        let end = now.addingTimeInterval(900) // Monitor for 15 minutes
        let startComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: now)
        let endComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: end)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        do {
            try center.startMonitoring(.blockingEvent, during: schedule, events: [eventName: event])
            print("Started monitoring device activity event with threshold: \(duration) seconds")
        } catch {
            print("Failed to start device activity event monitoring: \(error)")
        }
    }
    
    func initialize(with selectedApps: FamilyActivitySelection) {
        self.selectedApps = selectedApps
        saveState()
    }
    
    func restoreState() {
        if let savedApps = settings.loadSelectedApps() {
            selectedApps = savedApps
        }
    }
    
    private func saveState() {
        settings.saveSelectedApps(selectedApps)
    }
    
    func resetConfiguration() {
        selectedApps = FamilyActivitySelection()
        tokenMapper.loadMappings()
        settings.resetConfiguration()
    }
    
    func isValidConfiguration() -> Bool {
        let hasValidApps = !selectedApps.applications.isEmpty
        return hasValidApps
    }
    
    func getSelectedApps() -> FamilyActivitySelection {
        return selectedApps
    }
}

