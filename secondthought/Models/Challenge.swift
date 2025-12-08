//
//  Challenge.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/8/25.
//

import Foundation
import SwiftUI

protocol Challenge: View {
    var name: String { get } // unique
    var displayName: String { get }
    var description: String { get }
    var icon: String { get }
    var isPremium: Bool { get }
    
}

extension Challenge {
    
    @MainActor
    func openApp(urlScheme: String, customDelay: Double?) {
        guard let url = URL(string: urlScheme) else {
            return
        }

        AppSettings.shared.setContinueTimestamp(for: urlScheme)

        Task {
            await UIApplication.shared.open(url)
            ChallengeService.shared.challengeCompleted(urlScheme: urlScheme, customDelay: customDelay)
        }
    }
}
