//
//  ContentView.swift
//  secondthought
//
//  Created by Yaseen Halabi on 7/26/25.
//

import SwiftUI
import DeviceActivity
import FamilyControls
import ManagedSettings


struct ContentView: View {
    @State private var showContinueScreen = false
    @State private var urlScheme = ""
    @State private var hasRequestedPermissions = false
    @State private var showAppSelector = false
    @State private var selectedApps = FamilyActivitySelection()
    @State private var codeRegenerationTrigger: UUID = UUID()
    
    @ObservedObject private var settings = AppSettings.shared
    
    private let logger = Logger.shared
    private let blockingManager = AppBlockingManager.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    
    var body: some View {
        VStack {
            if showAppSelector {
                AppSelectorView(selectedApps: $selectedApps) {
                    saveAppConfiguration()
                    showAppSelector = false
                }
            } else if showContinueScreen {
                ContinueScreen(
                    urlScheme: urlScheme,
                    settings: settings,
                    regenerationTrigger: codeRegenerationTrigger,
                    onAppOpened: { scheme, customDelay in
                        blockingManager.startMonitoring(for: scheme, timingMode: settings.timingMode, customDelay: customDelay)
                    }
                )
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
        
        logger.ui("App became active, saved scheme: '\(savedScheme)'")
        
        if !savedScheme.isEmpty {
            logger.ui("Showing continue screen for scheme: \(savedScheme)")
            
            settings.clearSelectedAppScheme()
            blockingManager.restoreState()
            
            urlScheme = savedScheme
            codeRegenerationTrigger = UUID()
            showContinueScreen = true
        } else {
            logger.ui("No saved scheme, showing home screen")
            showContinueScreen = false
        }
    }
    
    private func requestPermissionsIfNeeded() {
        guard !hasRequestedPermissions else { return }
        
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        logger.info("Permission check - status: \(authStatus)")
        
        if authStatus == .notDetermined {
            logger.info("Requesting Screen Time permissions")
            hasRequestedPermissions = true
            
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    logger.success("Screen Time permission granted")
                    handlePermissionGranted()
                } catch {
                    logger.error("Screen Time permission denied: \(error)")
                    handlePermissionDenied()
                }
            }
        } else if authStatus == .approved {
            logger.success("Screen Time permissions already granted")
            handlePermissionGranted()
        } else {
            logger.warning("Screen Time permissions denied or restricted")
            handlePermissionDenied()
        }
    }
    
    private func handlePermissionGranted() {
        logger.success("DeviceActivity API is now available")
    }
    
    private func handlePermissionDenied() {
        logger.warning("DeviceActivity API not available - limited functionality")
    }
    
    
    
    private func checkIfAppsConfigured() {
        logger.info("Checking app configuration")
        
        if settings.hasConfiguredApps {
            logger.info("Loading existing configuration")
            loadAppConfiguration()
            
            if blockingManager.validateConfiguration() {
                logger.success("Valid configuration found")
            } else {
                logger.warning("Invalid configuration - forcing reconfiguration")
                blockingManager.resetConfiguration()
                settings.hasConfiguredApps = false
            }
        } else {
            logger.info("No previous configuration found")
        }
    }
    
    
    private func saveAppConfiguration() {
        logger.storage("Saving app configuration with \(selectedApps.applications.count) apps")
        
        UserDefaultsService.shared.saveSelectedApps(selectedApps)
        settings.hasConfiguredApps = true
        blockingManager.initialize(with: selectedApps)
        
        logger.storage("App configuration saved successfully")
    }
    
    private func loadAppConfiguration() {
        if let savedApps = UserDefaultsService.shared.loadSelectedApps() {
            selectedApps = savedApps
            blockingManager.initialize(with: selectedApps)
            logger.storage("Loaded \(selectedApps.applications.count) selected apps")
        }
    }
    
}



#Preview("On install") {
    ContentView()
}

#Preview("Home") {
    ContentView().onAppear {
        AppSettings.shared.hasConfiguredApps = true
        
    }
}

#Preview("Unlock Screen") {
    ContinueScreen(
        urlScheme: "instagram://",
        settings: AppSettings.shared,
        regenerationTrigger: UUID(),
        onAppOpened: { _, _ in }
    )
}
