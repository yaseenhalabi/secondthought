//
//  ChallengeCard.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/8/25.
//

import Foundation
import SwiftUI

struct ChallengeCard: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(challenge.title)
                .font(.headline)
                .foregroundStyle(Color.white)
            
            Text(challenge.description)
                .font(.body)
                .foregroundStyle(Color.white)
            Spacer(minLength: 0)
            HStack {
                Spacer()
                Image(systemName: challenge.icon)
                    .foregroundStyle(Color.white)
                    .font(.system(size: 40))
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 140, maxHeight: 140)
        .padding(12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.mainColor2, Color.mainColor1]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
