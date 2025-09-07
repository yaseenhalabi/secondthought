import Foundation
import SwiftUI

struct UnlockChallengesView: View {
    @ObservedObject private var challengeService = ChallengeService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Unlock Challenges").font(.headline)
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 40, maximum: .infinity)),
                GridItem(.flexible(minimum: 40, maximum: .infinity))
            ], spacing: 8) {
                ForEach(challengeService.availableChallenges, id: \.name) { challenge in
                    ChallengeCard(challenge: challenge, isSelected: challenge.name == challengeService.selectedChallenge.name)
                        .onTapGesture {
                            challengeService.selectedChallenge = challenge
                        }
                }
                AddChallengeCard()
            }
        }
        .padding(16)
        .background(Color.backgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
