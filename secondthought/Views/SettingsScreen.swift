//
//  SettingsScreen.swift
//  secondthought
//
//  Created by Yaseen Halabi on 7/26/25.
//

import SwiftUI
import FamilyControls


struct SettingsScreen: View {
    @State private var showContinueScreen = false
    @State private var urlScheme = ""
    @State private var hasRequestedPermissions = false
    @State private var showAppSelector = false
    @State private var selectedApps = FamilyActivitySelection()
    @State private var codeRegenerationTrigger: UUID = UUID()
    
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var challengeService = ChallengeService.shared
    
    private let blockingManager = AppBlockingManager.shared
    
    var body: some View {
        VStack {
            if showAppSelector {
                AppSelectorView(selectedApps: $selectedApps) {
                    saveAppConfiguration()
                    showAppSelector = false
                }
            } else if showContinueScreen {
                challengeService.view(
                    for: challengeService.selectedChallenge, 
                    urlScheme: urlScheme
                )
                .id(codeRegenerationTrigger)
            } else {
                VStack(spacing: 16){
                    UnlockChallengesView()
                    
                    VStack(spacing: 16) {
                        SettingItem(icon: "gear", title: "Settings") {
                            // Settings action
                        }
                        
                        SettingItem(icon: "arrow.clockwise", title: "Refresh") {
                            // Refresh action
                        }
                        
                        SettingItem(icon: "person", title: "Option", isToggled: .constant(true))
                    }
                    
                    if !settings.hasConfiguredApps {
                        Button("Configure Apps") {
                            showAppSelector = true
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.background)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            handleAppBecameActive()
        }
        .onAppear {
            requestPermissionsIfNeeded()
            checkIfAppsConfigured()
            blockingManager.restoreState()
        }
    }
    
    private func handleAppBecameActive() {
        let savedScheme = settings.selectedAppScheme
        
        if !savedScheme.isEmpty {
            settings.clearSelectedAppScheme()
            blockingManager.restoreState()
            
            urlScheme = savedScheme
            codeRegenerationTrigger = UUID()
            showContinueScreen = true
        } else {
            showContinueScreen = false
        }
    }
    
    private func requestPermissionsIfNeeded() {
        guard !hasRequestedPermissions else { return }
        
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        
        if authStatus == .notDetermined {
            hasRequestedPermissions = true
            
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    handlePermissionGranted()
                } catch {
                    handlePermissionDenied()
                }
            }
        } else if authStatus == .approved {
            handlePermissionGranted()
        } else {
            handlePermissionDenied()
        }
    }
    
    private func handlePermissionGranted() {
        // Was previously a log
    }
    
    private func handlePermissionDenied() {
        // Was previously a log
    }
    
    
    
    private func checkIfAppsConfigured() {
        if settings.hasConfiguredApps {
            loadAppConfiguration()
            
            if !blockingManager.validateConfiguration() {
                blockingManager.resetConfiguration()
                settings.hasConfiguredApps = false
            }
        }
    }
    
    
    private func saveAppConfiguration() {
        settings.saveSelectedApps(selectedApps)
        settings.hasConfiguredApps = true
        blockingManager.initialize(with: selectedApps)
    }
    
    private func loadAppConfiguration() {
        if let savedApps = settings.loadSelectedApps() {
            selectedApps = savedApps
            blockingManager.initialize(with: selectedApps)
        }
    }
    
}



#Preview("On install") {
    SettingsScreen()
}

#Preview("Home") {
    SettingsScreen().onAppear {
        AppSettings.shared.hasConfiguredApps = true
        
    }
}

#Preview("Unlock Screen") {
    struct ChallengePreview: View {
        @ObservedObject private var challengeService = ChallengeService.shared
        var body: some View {
            challengeService.view(for: challengeService.selectedChallenge, urlScheme: "instagram://")
        }
    }
    return ChallengePreview()
}
