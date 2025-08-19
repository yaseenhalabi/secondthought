import AppIntents
import SwiftUI
import UIKit
import FamilyControls
import ManagedSettings

// NOTE: If you see 'Cannot find AppBlockingManager in scope', ensure 'AppBlockingManager.swift' is included in your Intents extension target.

struct ActivateSecondThoughtIntent: AppIntent {
    static var title: LocalizedStringResource = "Activate Second Thought"
    static var description = IntentDescription("Activate Second Thought for an app")
    static var supportedModes: IntentModes = [.background, .foreground(.dynamic)]
    
    @Parameter(title: "URL Scheme", description: "Enter the app's URL scheme (e.g. instagram://)")
    var urlScheme: String
    
    private let logger = Logger.shared
    private let blockingManager = AppBlockingManager.shared
    private let settings = AppSettings.shared
    
    func perform() async throws -> some IntentResult {
        logger.intent("Intent started for scheme: '\(urlScheme)'")
        
        blockingManager.unblockAppForScheme(urlScheme)
        
        if settings.shouldSkipForegrounding(for: urlScheme) {
            logger.intent("Skipping foreground - user recently continued")
        } else {
            logger.intent("Proceeding with foreground")
            settings.selectedAppScheme = urlScheme
            
            do {
                try await continueInForeground(alwaysConfirm: false)
                logger.intent("Foreground operation completed")
            } catch {
                logger.error("Couldn't bring app to foreground: \(error)")
            }
        }
        
        logger.intent("Intent completed")
        return .result()
    }
}
