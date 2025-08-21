//
//  SettingItem.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/19/25.
//

import Foundation
import SwiftUI

struct SettingItem: View {
    let icon: String
    let title: String
    let hasToggle: Bool
    @Binding var isToggled: Bool
    let action: (() -> Void)?
    
    init(icon: String, title: String, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.hasToggle = false
        self._isToggled = .constant(false)
        self.action = action
    }
    
    init(icon: String, title: String, isToggled: Binding<Bool>) {
        self.icon = icon
        self.title = title
        self.hasToggle = true
        self._isToggled = isToggled
        self.action = nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with purple background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mainColor1)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundStyle(Color.white)
                    .font(.system(size: 16, weight: .medium))
            }
            
            // Title
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.primary)
            
            Spacer()
            
            // Right side content
            if hasToggle {
                Toggle("", isOn: $isToggled)
                    .labelsHidden()
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.secondary)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            if !hasToggle {
                action?()
            }
        }
    }
}

