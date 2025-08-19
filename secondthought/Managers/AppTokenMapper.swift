import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
class AppTokenMapper {
    static let shared = AppTokenMapper()
    
    private let logger = Logger.shared
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
        learnedMappings = storage.loadLearnedMappings()
        
        let activeMappings = storage.loadActiveMappings()
        for (scheme, token) in activeMappings {
            learnedMappings[scheme] = token
        }
        
        logger.storage("Loaded \(learnedMappings.count) total mappings", context: "AppTokenMapper")
    }
    
    func getToken(for urlScheme: String, from selectedApps: FamilyActivitySelection) -> ApplicationToken? {
        logger.debug("Getting token for scheme: \(urlScheme)", context: "AppTokenMapper")
        
        if let learnedToken = learnedMappings[urlScheme] {
            logger.success("Found learned mapping for \(urlScheme)", context: "AppTokenMapper")
            return learnedToken
        }
        
        logger.info("No learned mapping found, attempting auto-detection", context: "AppTokenMapper")
        
        guard schemeToBundle[urlScheme] != nil else {
            logger.error("No bundle ID found for scheme: \(urlScheme)", context: "AppTokenMapper")
            return nil
        }
        
        let availableTokens = Array(selectedApps.applicationTokens)
        guard let firstToken = availableTokens.first else {
            logger.error("No available tokens to assign", context: "AppTokenMapper")
            return nil
        }
        
        learnToken(firstToken, for: urlScheme)
        return firstToken
    }
    
    func learnToken(_ token: ApplicationToken, for urlScheme: String) {
        learnedMappings[urlScheme] = token
        storage.saveLearnedMappings(learnedMappings)
        logger.success("Learned new mapping: \(urlScheme) -> \(token)", context: "AppTokenMapper")
    }
    
    func getLearnedMappings() -> [String: ApplicationToken] {
        return learnedMappings
    }
    
    func updateActiveMappings(_ mappings: [String: ApplicationToken]) {
        for (scheme, token) in mappings {
            learnedMappings[scheme] = token
        }
        storage.saveActiveMappings(mappings)
        logger.storage("Updated active mappings with \(mappings.count) entries", context: "AppTokenMapper")
    }
    
    func getBundleIdentifier(for urlScheme: String) -> String? {
        return schemeToBundle[urlScheme]
    }
}
