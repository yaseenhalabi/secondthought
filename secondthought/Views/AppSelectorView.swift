//
//  AppSelectorView.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/21/25.
//

import SwiftUI
import FamilyControls

struct AppSelectorView: View {
    @Binding var selectedApps: FamilyActivitySelection
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Apps to Monitor")
                .font(.title)
                .padding()
            
            Text("Choose the apps you want Second Thought to monitor and block. The app will automatically learn which apps you select, and you can adjust the timing mode on the home screen.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            FamilyActivityPicker(selection: $selectedApps)
                .frame(height: 400)
            
            Button("Save Apps") {
                onComplete()
            }
            .font(.title2)
            .padding()
            .background(selectedApps.applications.isEmpty ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(selectedApps.applications.isEmpty)
        }
        .padding()
    }
}
