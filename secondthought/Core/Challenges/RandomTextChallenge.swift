//
//  RandomTextChallenge.swift
//  secondthought
//
//  Created by Gemini on 8/28/25.
//

import SwiftUI

struct RandomTextChallenge: Challenge {
    var name: String = "RandomText"
    var displayName: String = "Random Text"
    var description: String = "Use a random string of generated characters."
    var icon: String = "textformat.abc"
    var isPremium: Bool = false

    var body: some View {
        EmptyView()
    }
}
