//
//  UnlockChallengesView.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/8/25.
//

import Foundation
import SwiftUI

struct UnlockChallengesView: View {
    let challenges: [any Challenge] = [
        RandomTextChallenge(),
        ChessPuzzleChallenge(),
        BlackjackChallenge()
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Unlock Challenges").font(.headline)
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 40, maximum: .infinity)),
                GridItem(.flexible(minimum: 40, maximum: .infinity))
            ], spacing: 8) {
                ForEach(challenges, id: \.name) { challenge in
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
