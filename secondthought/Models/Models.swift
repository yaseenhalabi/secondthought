import Foundation

enum TimingMode: String, CaseIterable {
    case defaultMode = "default"
    case randomMode = "random"
    case dynamicMode = "dynamic"
    
    var displayName: String {
        switch self {
        case .defaultMode: return "Default Mode"
        case .randomMode: return "Random Mode" 
        case .dynamicMode: return "Dynamic Mode"
        }
    }
}
