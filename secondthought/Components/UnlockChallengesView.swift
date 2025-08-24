//
//  UnlockChallengesView.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/8/25.
//

import Foundation
import SwiftUI

struct UnlockChallengesView: View {
    let challenges = [
        Challenge(title: "Random Text", description: "Use a random string of generated characters.", icon: "textformat.abc", isStarred: false),
        Challenge(title: "Chess Puzzle", description: "Solve a chess puzzle that get harder each time you unlock.", icon: "crown", isStarred: true),
        Challenge(title: "BlackJack", description: "Win a round of blackjack to continue", icon: "suit.club.fill", isStarred: true),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Unlock Challenges").font(.headline)
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 40, maximum: .infinity)),
                GridItem(.flexible(minimum: 40, maximum: .infinity))
            ], spacing: 8) {
                ForEach(challenges) { challenge in
                    ChallengeCard(challenge: challenge)
                }
                AddChallengeCard()
            }
        }
        .padding(16)
        .background(Color.backgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
