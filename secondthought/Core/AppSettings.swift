import Foundation
import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let storage = UserDefaultsService.shared
    
    @Published var hasConfiguredApps: Bool {
        didSet {
            storage.hasConfiguredApps = hasConfiguredApps
        }
    }
    
    private init() {
        self.hasConfiguredApps = storage.hasConfiguredApps
    }
    
    
    
    func setContinueTimestamp(for scheme: String) {
        let now = Date().timeIntervalSince1970
        storage.setContinueTimestamp(now, for: scheme)
    }
    
    func shouldSkipForegrounding(for scheme: String) -> Bool {
        let lastContinueTime = storage.getContinueTimestamp(for: scheme)
        let timeSinceContinue = Date().timeIntervalSince1970 - lastContinueTime
        let continueCooldownPeriod: Double = 3.0
        
        let recentlyContinued = lastContinueTime > 0 && timeSinceContinue < continueCooldownPeriod
        
        return recentlyContinued
    }
    
    var selectedAppScheme: String {
        get { storage.selectedAppScheme }
        set { 
            storage.selectedAppScheme = newValue
        }
    }
    
    func clearSelectedAppScheme() {
        selectedAppScheme = ""
    }
}
