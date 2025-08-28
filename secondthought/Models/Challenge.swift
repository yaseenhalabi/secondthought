//
//  Challenge.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/8/25.
//

import Foundation
import SwiftUI

//struct Challenge: Identifiable {
//      let id = UUID()
//      let title: String
//      let description: String
//      let icon: String
//      let isStarred: Bool
//  }


protocol Challenge: View {
    var name: String { get } // unique
    var displayName: String { get }
    var description: String { get }
    var icon: String { get }
    var isPremium: Bool { get }
}
