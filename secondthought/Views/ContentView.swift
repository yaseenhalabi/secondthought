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
                VStack(){
                    UnlockChallengesView()
                    
//                    if settings.hasConfiguredApps {
//                        VStack(spacing: 15) {
//                            Text("Timing Mode")
//                                .font(.headline)
//                                .foregroundColor(.primary)
//                            
//                            Picker("Timing Mode", selection: $settings.timingMode) {
//                                ForEach(TimingMode.allCases, id: \.self) { mode in
//                                    Text(mode.displayName).tag(mode)
//                                }
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            .padding(.horizontal)
//                            
//                            Text("Current mode: \(settings.timingMode.displayName)")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            
//                            Divider()
//                                .padding(.vertical, 8)
//                            
//                            Text("Verification Code Length")
//                                .font(.headline)
//                                .foregroundColor(.primary)
//                            
//                            Stepper(value: $settings.verificationCodeLength, in: 3...8) {
//                                Text("\(settings.verificationCodeLength) characters")
//                                    .font(.body)
//                            }
//                            
//                            Text("Users must type a \(settings.verificationCodeLength)-character code to continue")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding()
//                        .background(Color(.systemGray6))
//                        .cornerRadius(12)
//                        .padding(.horizontal)
//                    }
//                    
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

struct ContinueScreen: View {
    let urlScheme: String
    let settings: AppSettings
    let regenerationTrigger: UUID
    let onAppOpened: (String, Double?) -> Void
    
    private let logger = Logger.shared
    
    @State private var generatedCode: String = ""
    @State private var userInput: String = ""
    @State private var isCodeCorrect: Bool = false
    @State private var showError: Bool = false
    @State private var hasAppeared: Bool = false
    
    private var timingDescription: String {
        return settings.timingDescription
    }
    
    private var instructionText: String {
        return settings.instructionText
    }
    
    private func generateRandomCode() {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        
        let length = settings.timingMode == .dynamicMode ? 20 : settings.verificationCodeLength
        generatedCode = String((0..<length).map { _ in characters.randomElement()! })
        logger.ui("Generated verification code (\(settings.timingMode.rawValue) mode): \(generatedCode)")
    }
    
    private func validateInput() {
        if settings.timingMode == .dynamicMode {
            validateDynamicInput()
        } else {
            validateExactInput()
        }
    }
    
    private func validateExactInput() {
        if userInput == generatedCode {
            isCodeCorrect = true
            showError = false
            logger.success("Code verification successful")
        } else {
            showError = true
            isCodeCorrect = false
            logger.warning("Code verification failed. Expected: \(generatedCode), Got: \(userInput)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                generateRandomCode()
                userInput = ""
                showError = false
            }
        }
    }
    
    private func validateDynamicInput() {
        guard !userInput.isEmpty else {
            showError = true
            isCodeCorrect = false
            logger.warning("Dynamic validation failed: Empty input")
            return
        }
        
        if generatedCode.hasPrefix(userInput) {
            isCodeCorrect = true
            showError = false
            let earnedSeconds = userInput.count * 2
            logger.success("Dynamic validation successful: \(userInput.count) characters = \(earnedSeconds) seconds")
        } else {
            showError = true
            isCodeCorrect = false
            logger.warning("Dynamic validation failed. Input '\(userInput)' is not a valid prefix of '\(generatedCode)'")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                generateRandomCode()
                userInput = ""
                showError = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("App Unblocked")
                .font(.title)
                .foregroundColor(.green)
            
            Text("The app has been unblocked. \(timingDescription)")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                Text(instructionText)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(generatedCode)
                    .font(.system(.title, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .foregroundColor(.primary)
                
                TextField("Enter code", text: $userInput)
                    .font(.system(.title2, design: .monospaced))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.none)
                    .onChange(of: userInput) { oldValue, newValue in
                        let maxLength = settings.timingMode == .dynamicMode ? 20 : settings.verificationCodeLength
                        let filtered = String(newValue.prefix(maxLength).filter { char in
                            char.isLetter || char.isNumber
                        })
                        if filtered != newValue {
                            userInput = filtered
                        }
                    }
                
                if settings.timingMode == .dynamicMode && !userInput.isEmpty {
                    let earnedSeconds = userInput.count * 2
                    Text("Earning: \(earnedSeconds) seconds (\(userInput.count) characters)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if showError {
                    Text("Incorrect code. Try again...")
                        .font(.caption)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            
            Button("Continue to App") {
                validateInput()
                if isCodeCorrect {
                    let customDelay = settings.timingMode == .dynamicMode ? Double(userInput.count * 2) : nil
                    openApp(customDelay: customDelay)
                }
            }
            .font(.title2)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                generateRandomCode()
                // Reset verification state for clean start
                userInput = ""
                isCodeCorrect = false
                showError = false
            }
        }
        .onChange(of: regenerationTrigger) {
            // Regenerate code whenever trigger changes (intent runs)
            generateRandomCode()
            userInput = ""
            isCodeCorrect = false
            showError = false
        }
    }
    
    @MainActor
    private func openApp(customDelay: Double? = nil) {
        logger.ui("Continue button pressed for scheme: '\(urlScheme)'")
        
        guard let url = URL(string: urlScheme) else { 
            logger.error("Invalid URL scheme: \(urlScheme)")
            return 
        }
        
        settings.setContinueTimestamp(for: urlScheme)
        
        Task {
            logger.ui("Opening URL: \(url)")
            await UIApplication.shared.open(url)
            
            onAppOpened(urlScheme, customDelay)
        }
    }
}

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

#Preview("On install") {
    ContentView()
}

#Preview("Home") {
    ContentView().onAppear {
        AppSettings.shared.hasConfiguredApps = true
    }
}
