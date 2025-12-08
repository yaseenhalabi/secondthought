import AppIntents
import SwiftUI
import UIKit
import FamilyControls

struct ActivateSecondThoughtIntent: AppIntent {
    static let title: LocalizedStringResource = "Activate Second Thought"
    static let description = IntentDescription("Activate Second Thought for an app")
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]
    
    @Parameter(title: "URL Scheme", description: "Enter the app's URL scheme (e.g. instagram://)")
    var urlScheme: String
    
    @MainActor func perform() async throws -> some IntentResult {
        let settings = AppSettings.shared
        // All code here runs on the main actor due to @MainActor on the type.
        if !settings.shouldSkipForegrounding(for: urlScheme) {
            settings.selectedAppScheme = urlScheme
            do {
                try await continueInForeground(alwaysConfirm: false)
            } catch {
                // Couldn't bring app to foreground, not critical
            }
        }
        
        return .result()
    }
}

