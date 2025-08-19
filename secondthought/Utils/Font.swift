//
//  Font.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/8/25.
//

import Foundation
import SwiftUI

extension Font {
    private static let fontFamily = "Lexend Deca"
    
    static let largeTitle = Font.custom(fontFamily, size: 28).weight(.semibold)
    static let title = Font.custom(fontFamily, size: 20).weight(.medium)
    static let headline = Font.custom(fontFamily, size: 16).weight(.medium)
    static let body = Font.custom(fontFamily, size: 14).weight(.regular)
}
