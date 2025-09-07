import SwiftUI
import Combine

struct RandomTextChallenge: Challenge {
    var name: String = "RandomText"
    var displayName: String = "Random Text"
    var description: String = "Use a random string of generated characters."
    var icon: String = "textformat.abc"
    var isPremium: Bool = false

    var urlScheme: String?
    var onAppOpened: ((String, Double?) -> Void)?

    @StateObject private var settings = RandomTextChallengeSettings()
    @State private var generatedCode: String = ""
    @State private var userInput: String = ""
    @State private var isCodeCorrect: Bool = false
    @State private var showError: Bool = false
    @State private var hasAppeared: Bool = false
    @FocusState private var isInputFocused: Bool

    init() {
        self.urlScheme = nil
        self.onAppOpened = nil
    }

    init(urlScheme: String, onAppOpened: @escaping (String, Double?) -> Void) {
        self.urlScheme = urlScheme
        self.onAppOpened = onAppOpened
    }

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
        if urlScheme != nil && onAppOpened != nil {
            VStack(spacing: 20) {
                Text(generatedCode)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.mainColor1)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

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

                Button {
                    validateInput()
                    if isCodeCorrect {
                        let customDelay = settings.timingMode == .dynamicMode ? Double(userInput.count * 2) : settings.blockDelay
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
        } else {
            EmptyView()
        }
    }

    @MainActor
    private func openApp(customDelay: Double? = nil) {
        guard let urlScheme, let onAppOpened, let url = URL(string: urlScheme) else {
            return
        }

        AppSettings.shared.setContinueTimestamp(for: urlScheme)

        Task {
            await UIApplication.shared.open(url)
            onAppOpened(urlScheme, customDelay)
        }
    }
}

class RandomTextChallengeSettings: ObservableObject {
    enum TimingMode: String {
        case defaultMode = "default"
        case randomMode = "random"
        case dynamicMode = "dynamic"
    }

    @Published var timingMode: TimingMode {
        didSet {
            // In a real app, you'd save this to UserDefaults
        }
    }

    @Published var verificationCodeLength: Int {
        didSet {
            // In a real app, you'd save this to UserDefaults
        }
    }

    init() {
        // In a real app, you'd load this from UserDefaults
        self.timingMode = .defaultMode
        self.verificationCodeLength = 4
    }

    var timingDescription: String {
        switch timingMode {
        case .defaultMode:
            return "You'll have 10 seconds before it's blocked again."
        case .randomMode:
            return "You'll have 1-10 seconds (randomly) before it's blocked again."
        case .dynamicMode:
            return "Enter any amount - you get 2 seconds per character."
        }
    }

    var instructionText: String {
        switch timingMode {
        case .defaultMode, .randomMode:
            return "Enter this code to continue:"
        case .dynamicMode:
            return "Enter the beginning of this code:"
        }
    }
    
    var blockDelay: Double {
        switch timingMode {
        case .defaultMode:
            return 10.0
        case .randomMode:
            return Double.random(in: 1.0...10.0)
        case .dynamicMode:
            return 2.0 // This is a fallback, the actual delay is calculated from input length
        }
    }
}
