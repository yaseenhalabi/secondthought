import Foundation
import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let storage = UserDefaultsService.shared
    
    @Published var timingMode: TimingMode {
        didSet {
            storage.timingMode = timingMode.rawValue
        }
    }
    
    @Published var verificationCodeLength: Int {
        didSet {
            storage.verificationCodeLength = verificationCodeLength
        }
    }
    
    @Published var hasConfiguredApps: Bool {
        didSet {
            storage.hasConfiguredApps = hasConfiguredApps
        }
    }
    
    private init() {
        let savedModeString = storage.timingMode
        self.timingMode = TimingMode(rawValue: savedModeString) ?? .defaultMode
        self.verificationCodeLength = storage.verificationCodeLength
        self.hasConfiguredApps = storage.hasConfiguredApps
    }
    
    var timingDescription: String {
        switch timingMode {
        case .defaultMode:
            return "You'll have 10 seconds before it's blocked again."
        case .randomMode:
            return "You'll have 1-10 seconds (randomly) before it's blocked again."
        case .dynamicMode:
            return "Enter any amount - you get 2 seconds per character."
        }
    }
    
    var instructionText: String {
        switch timingMode {
        case .defaultMode, .randomMode:
            return "Enter this code to continue:"
        case .dynamicMode:
            return "Enter the beginning of this code:"
        }
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
