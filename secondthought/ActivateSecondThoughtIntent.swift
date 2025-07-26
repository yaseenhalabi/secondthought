import Foundation
import AppIntents
import SwiftUI
import UIKit

struct AppToOpen: @preconcurrency AppEntity {
    var id: UUID
    var name: String = ""
    var urlScheme: String = ""
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "App to open")
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    static var defaultQuery = AppToOpenQuery()
}

@preconcurrency
struct AppToOpenQuery: EntityQuery {
    func entities(for identifiers: [AppToOpen.ID]) async throws -> [AppToOpen] {
        return []
    }
    
    func suggestedEntities() async throws -> [AppToOpen] {
        return []
    }
}

struct ActivateSecondThoughtIntent: @preconcurrency AppIntent {
    static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Open a popular app from your device")
    static var supportedModes: IntentModes =  [.background, .foreground(.dynamic)]
    
    @Parameter(title: "App Name", description: "Choose which app to open")
    var appToOpen: AppToOpen
    
    func perform() async throws -> some IntentResult {
        guard let url = URL(string: appToOpen.urlScheme) else {
            return .result()
        }
        
        let canOpen = UIApplication.shared.canOpenURL(url)
        
        if canOpen {
            print("Opening \(appToOpen.urlScheme) with URL scheme: \(appToOpen.urlScheme)")
            await UIApplication.shared.open(url)
            
            UserDefaults().set(true, forKey: "showContinueScreen")
            
            do {
                try await continueInForeground(alwaysConfirm: false)
            } catch {
                print("Couldn't bring app to foreground after opening \(appToOpen.urlScheme)")
            }
            
            return .result()
        } else {
            return .result()
        }
    }
}
