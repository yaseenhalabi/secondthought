import SwiftUI

struct ContinueScreen: View {
    let urlScheme: String
    let onAppOpened: (String, Double?) -> Void
    
    @ObservedObject private var challengeService = ChallengeService.shared
    
    var body: some View {
        challengeService.view(
            for: challengeService.selectedChallenge, 
            urlScheme: urlScheme, 
            onAppOpened: onAppOpened
        )
    }
}
