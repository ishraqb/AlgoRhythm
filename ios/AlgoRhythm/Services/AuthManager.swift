import SwiftUI

/// Owns the signed-in state and brokers the Cognito flows for the UI. The
/// derived Cognito `sub` is the user's stable ID and becomes the DynamoDB
/// partition key once we sync.
@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// Set after a successful sign-up so the UI can show the code-entry step.
    @Published var awaitingConfirmation = false

    private(set) var userSub: String?

    private let config = AppConfig.shared
    private let client: CognitoAuthClient

    private enum TokenKey {
        static let id = "idToken"
        static let access = "accessToken"
        static let sub = "userSub"
    }

    init() {
        client = CognitoAuthClient(region: config.region, clientId: config.userPoolClientId)
        restoreSession()
    }

    var backendConfigured: Bool { config.isConfigured }

    // MARK: - Flows

    func signUp(email: String, password: String) async {
        await run { [self] in
            try await client.signUp(email: email, password: password)
            awaitingConfirmation = true
        }
    }

    func confirm(email: String, code: String) async {
        await run { [self] in
            try await client.confirm(email: email, code: code)
            awaitingConfirmation = false
        }
    }

    func signIn(email: String, password: String) async {
        await run { [self] in
            let tokens = try await client.signIn(email: email, password: password)
            persist(tokens)
            isAuthenticated = true
        }
    }

    /// Local-only fallback when no backend is configured, so the app still runs
    /// in the simulator. Progress stays on-device in this mode.
    func continueAsGuest() {
        let sub = KeychainStore.get(TokenKey.sub) ?? UUID().uuidString
        KeychainStore.set(sub, for: TokenKey.sub)
        userSub = sub
        isAuthenticated = true
    }

    func signOut() {
        KeychainStore.remove(TokenKey.id)
        KeychainStore.remove(TokenKey.access)
        isAuthenticated = false
        userSub = nil
    }

    /// Hooks the deck's performance sync up to the backend once we have a token.
    func attach(to deck: DeckViewModel) {
        guard config.isConfigured,
              let endpoint = config.appSyncEndpoint,
              let idToken = KeychainStore.get(TokenKey.id) else {
            return
        }
        let syncer = AppSyncClient(endpoint: endpoint, idToken: idToken, userId: userSub ?? "")
        deck.attachSyncer(syncer)
    }

    // MARK: - Helpers

    private func run(_ work: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            try await work()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func persist(_ tokens: CognitoAuthClient.Tokens) {
        KeychainStore.set(tokens.idToken, for: TokenKey.id)
        KeychainStore.set(tokens.accessToken, for: TokenKey.access)
        userSub = Self.subject(fromIdToken: tokens.idToken)
        if let sub = userSub { KeychainStore.set(sub, for: TokenKey.sub) }
    }

    private func restoreSession() {
        if KeychainStore.get(TokenKey.id) != nil {
            userSub = KeychainStore.get(TokenKey.sub)
            isAuthenticated = true
        }
    }

    /// Pulls the `sub` claim out of a JWT without verifying the signature; the
    /// token came straight from our HTTPS call to Cognito, and the server
    /// re-verifies it on every request.
    private static func subject(fromIdToken token: String) -> String? {
        let segments = token.split(separator: ".")
        guard segments.count > 1 else { return nil }
        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["sub"] as? String
    }
}
