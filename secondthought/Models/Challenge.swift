//
//  Challenge.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/8/25.
//

import Foundation
import SwiftUI

struct Challenge: Identifiable {
      let id = UUID()
      let title: String
      let description: String
      let icon: String
      let color: Color
      let isStarred: Bool
  }
