import SwiftUI

/// Sign-in / sign-up screen. Handles three states: signing in, signing up, and
/// entering the emailed confirmation code after sign-up.
struct AuthView: View {
    @EnvironmentObject private var auth: AuthManager

    private enum Mode { case signIn, signUp }
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var code = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 22) {
                branding
                if auth.awaitingConfirmation {
                    confirmationForm
                } else {
                    credentialsForm
                }
                if let message = auth.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Theme.review)
                        .multilineTextAlignment(.center)
                }
                if !auth.backendConfigured {
                    guestFallback
                }
            }
            .padding(28)
        }
    }

    private var branding: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 50))
                .foregroundStyle(Theme.accent)
            Text("AlgoRhythm")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
            Text("Swipe your way to interview-ready")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.bottom, 10)
    }

    private var credentialsForm: some View {
        VStack(spacing: 14) {
            field("Email", text: $email, keyboard: .emailAddress)
            secureField("Password", text: $password)

            primaryButton(mode == .signIn ? "Sign In" : "Create Account") {
                Task {
                    if mode == .signIn {
                        await auth.signIn(email: email, password: password)
                    } else {
                        await auth.signUp(email: email, password: password)
                    }
                }
            }

            Button {
                auth.errorMessage = nil
                mode = mode == .signIn ? .signUp : .signIn
            } label: {
                Text(mode == .signIn ? "New here? Create an account" : "Have an account? Sign in")
                    .font(.footnote)
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var confirmationForm: some View {
        VStack(spacing: 14) {
            Text("Enter the code we emailed to \(email).")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            field("Confirmation code", text: $code, keyboard: .numberPad)
            primaryButton("Confirm") {
                Task { await auth.confirm(email: email, code: code) }
            }
        }
    }

    private var guestFallback: some View {
        VStack(spacing: 6) {
            Text("Backend not configured")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
            Button("Continue without an account") {
                auth.continueAsGuest()
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.top, 8)
    }

    // MARK: - Small builders

    private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func secureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
            .foregroundStyle(.white)
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if auth.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(auth.isLoading)
    }
}
