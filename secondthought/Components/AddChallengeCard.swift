//
//  AddChallengeCard.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/8/25.
//

import Foundation
import SwiftUI

struct AddChallengeCard: View {
    var body: some View {
        VStack {
            Image(systemName: "plus")
                .foregroundStyle(Color.mainColor1)
                .font(.system(size: 40))
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 140, maxHeight: 140)
        .padding(12)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mainColor1, style: StrokeStyle(lineWidth: 3, dash: [5]))
        )
    }
}
