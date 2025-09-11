
import Foundation
import SwiftUI
import Combine

class ChallengeService: ObservableObject {
    static let shared = ChallengeService()
    
    private let blockingManager = AppBlockingManager.shared
    @Published var selectedChallenge: (any Challenge) {
        didSet {
            UserDefaultsService.shared.selectedChallengeName = selectedChallenge.name
        }
    }
    let availableChallenges: [any Challenge] = [
        RandomTextChallenge(),
        BlackjackChallenge(),
        ChessPuzzleChallenge()
    ]

    private init() {
        let savedChallengeName = UserDefaultsService.shared.selectedChallengeName
        if let challenge = availableChallenges.first(where: { $0.name == savedChallengeName }) {
            self.selectedChallenge = challenge
        } else {
            self.selectedChallenge = RandomTextChallenge()
        }
    }
    
    func challengeCompleted(urlScheme: String, customDelay: Double?) {
        blockingManager.startMonitoring(for: urlScheme, delay: customDelay)
    }

    @ViewBuilder
    func view(for challenge: any Challenge, urlScheme: String) -> some View {
        switch challenge.name {
        case "RandomText":
            RandomTextChallenge(urlScheme: urlScheme)
        case "Blackjack":
            BlackjackChallenge() // Will be implemented later
        case "ChessPuzzle":
            ChessPuzzleChallenge() // Will be implemented later
        default:
            Text("Unknown Challenge")
        }
    }
}


