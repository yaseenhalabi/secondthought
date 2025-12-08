import Foundation
import FamilyControls

class AppBlockingManager {
    static let shared = AppBlockingManager()
    
    private let settings = AppSettings.shared
    private let tokenMapper = AppTokenMapper.shared
    
    private var selectedApps = FamilyActivitySelection()
    
    private init() {
        restoreState()
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
    
    func validateConfiguration() -> Bool {
        let hasValidApps = !selectedApps.applications.isEmpty
        return hasValidApps
    }
    
    func getSelectedApps() -> FamilyActivitySelection {
        return selectedApps
    }
}

