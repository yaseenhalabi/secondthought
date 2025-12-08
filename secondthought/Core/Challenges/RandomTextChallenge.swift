import SwiftUI

struct RandomTextChallenge: Challenge {
    var name: String = "RandomText"
    var displayName: String = "Random Text"
    var description: String = "Use a random string of generated characters."
    var icon: String = "textformat.abc"
    var isPremium: Bool = false

    var urlScheme: String?

    @State private var generatedCode: String = ""
    @State private var userInput: String = ""
    @State private var isCodeCorrect: Bool = false
    @State private var hasAppeared: Bool = false
    @FocusState private var isInputFocused: Bool

    private let verificationCodeLength = 1
    private let blockDelay = 10.0

    init() {
        self.urlScheme = nil
    }

    init(urlScheme: String) {
        self.urlScheme = urlScheme
    }

    private func generateRandomCode() {
//        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let characters = "g"
        generatedCode = String((0..<verificationCodeLength).map { _ in characters.randomElement()! })
    }

    private func validateInput() {
        if userInput == generatedCode {
            isCodeCorrect = true
        } else {
            isCodeCorrect = false
            generateRandomCode()
            userInput = ""
        }
    }

    var body: some View {
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
                    let filtered = String(newValue.prefix(verificationCodeLength).filter { char in
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
                    if let urlScheme {
                        openApp(urlScheme: urlScheme, customDelay: blockDelay)
                    }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputFocused = true
                }
            }
        }
        
    }
}
