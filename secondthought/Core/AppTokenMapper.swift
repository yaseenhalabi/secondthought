import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
class AppTokenMapper {
    static let shared = AppTokenMapper()
    
    private let storage = UserDefaultsService.shared
    
    private var learnedMappings: [String: ApplicationToken] = [:]
    
    private init() {
        loadMappings()
    }
    
    private let schemeToBundle: [String: String] = [
        "instagram://": "com.burbn.instagram",
        "snapchat://": "com.toyopagroup.picaboo",
        "tiktok://": "com.zhiliaoapp.musically",
        "youtube://": "com.google.ios.youtube",
        "twitter://": "com.atebits.Tweetie2",
        "facebook://": "com.facebook.Facebook",
        "whatsapp://": "net.whatsapp.WhatsApp",
        "spotify://": "com.spotify.client",
        "reddit://": "com.reddit.Reddit"
    ]
    
    func loadMappings() {
        learnedMappings = storage.loadMappings()
    }
    
    func getToken(for urlScheme: String, from selectedApps: FamilyActivitySelection) -> ApplicationToken? {
        if let learnedToken = learnedMappings[urlScheme] {
            return learnedToken
        }
        
        guard schemeToBundle[urlScheme] != nil else {
            return nil
        }
        
        let availableTokens = Array(selectedApps.applicationTokens)
        guard let firstToken = availableTokens.first else {
            return nil
        }
        
        learnToken(firstToken, for: urlScheme)
        return firstToken
    }
    
    func learnToken(_ token: ApplicationToken, for urlScheme: String) {
        learnedMappings[urlScheme] = token
        storage.saveMappings(learnedMappings)
    }
    
    func getMappings() -> [String: ApplicationToken] {
        return learnedMappings
    }
}