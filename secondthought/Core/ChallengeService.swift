
import Foundation
import SwiftUI
import Combine

class ChallengeService: ObservableObject {
    static let shared = ChallengeService()

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

    @ViewBuilder
    func view(for challenge: any Challenge, urlScheme: String, onAppOpened: @escaping (String, Double?) -> Void) -> some View {
        switch challenge.name {
        case "RandomText":
            RandomTextChallenge(urlScheme: urlScheme, onAppOpened: onAppOpened)
        case "Blackjack":
            BlackjackChallenge() // Will be implemented later
        case "ChessPuzzle":
            ChessPuzzleChallenge() // Will be implemented later
        default:
            Text("Unknown Challenge")
        }
    }
}


