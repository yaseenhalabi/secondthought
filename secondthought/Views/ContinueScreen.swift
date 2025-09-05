//
//  ContinueScreen.swift
//  secondthought
//
//  Created by Yaseen Halabi on 8/21/25.
//

import SwiftUI

struct ContinueScreen: View {
    let urlScheme: String
    let settings: AppSettings
    let regenerationTrigger: UUID
    let onAppOpened: (String, Double?) -> Void
    
    @State private var generatedCode: String = ""
    @State private var userInput: String = ""
    @State private var isCodeCorrect: Bool = false
    @State private var showError: Bool = false
    @State private var hasAppeared: Bool = false
    @FocusState private var isInputFocused: Bool
    
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
        } else {
            showError = true
            isCodeCorrect = false
            
            generateRandomCode()
            userInput = ""
            showError = false
        }
    }
    
    private func validateDynamicInput() {
        guard !userInput.isEmpty else {
            showError = true
            isCodeCorrect = false
            return
        }
        
        if generatedCode.hasPrefix(userInput) {
            isCodeCorrect = true
            showError = false
        } else {
            showError = true
            isCodeCorrect = false
            
            generateRandomCode()
            userInput = ""
            showError = false
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Purple code display box
            Text(generatedCode)
                .font(.system(.title2, design: .monospaced))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color.mainColor1)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Text input field
            TextField("Enter code here", text: $userInput)
                .font(.system(.title2, design: .monospaced))
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .focused($isInputFocused)
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
            
            Spacer()
            
            // Continue button
            Button {
                validateInput()
                if isCodeCorrect {
                    let customDelay = settings.timingMode == .dynamicMode ? Double(userInput.count * 2) : nil
                    openApp(customDelay: customDelay)
                }
            } label: {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.primary)
            }
            .padding(.bottom, 40)
            
            if showError {
                Text("Incorrect code. Try again...")
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                generateRandomCode()
                userInput = ""
                isCodeCorrect = false
                showError = false
                isInputFocused = true
            }
        }
        .onChange(of: regenerationTrigger) {
            generateRandomCode()
            userInput = ""
            isCodeCorrect = false
            showError = false
        }
    }
    
    @MainActor
    private func openApp(customDelay: Double? = nil) {
        guard let url = URL(string: urlScheme) else { 
            return 
        }
        
        settings.setContinueTimestamp(for: urlScheme)
        
        Task {
            await UIApplication.shared.open(url)
            
            onAppOpened(urlScheme, customDelay)
        }
    }
}
