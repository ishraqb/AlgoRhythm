import Foundation

/// Talks to Amazon Cognito's user-pool API directly over HTTPS. These specific
/// actions (sign up, confirm, initiate auth) are unauthenticated and only need
/// the public app-client ID, so we avoid pulling in the full AWS SDK.
struct CognitoAuthClient {
    struct Tokens {
        let idToken: String
        let accessToken: String
        let refreshToken: String
    }

    enum AuthError: LocalizedError {
        case notConfigured
        case server(String)
        case malformedResponse

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Backend isn't configured yet."
            case .server(let message):
                return message
            case .malformedResponse:
                return "Something went wrong. Please try again."
            }
        }
    }

    let region: String
    let clientId: String

    private var endpoint: URL? {
        // Host is built from the configured region only (never user input),
        // so there's no untrusted URL being fetched here.
        URL(string: "https://cognito-idp.\(region).amazonaws.com/")
    }

    func signUp(email: String, password: String) async throws {
        _ = try await call(action: "SignUp", body: [
            "ClientId": clientId,
            "Username": email,
            "Password": password,
            "UserAttributes": [["Name": "email", "Value": email]]
        ])
    }

    func confirm(email: String, code: String) async throws {
        _ = try await call(action: "ConfirmSignUp", body: [
            "ClientId": clientId,
            "Username": email,
            "ConfirmationCode": code
        ])
    }

    func signIn(email: String, password: String) async throws -> Tokens {
        let json = try await call(action: "InitiateAuth", body: [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": clientId,
            "AuthParameters": ["USERNAME": email, "PASSWORD": password]
        ])

        guard let result = json["AuthenticationResult"] as? [String: Any],
              let idToken = result["IdToken"] as? String,
              let accessToken = result["AccessToken"] as? String else {
            throw AuthError.malformedResponse
        }
        let refresh = result["RefreshToken"] as? String ?? ""
        return Tokens(idToken: idToken, accessToken: accessToken, refreshToken: refresh)
    }

    private func call(action: String, body: [String: Any]) async throws -> [String: Any] {
        guard !clientId.isEmpty, let endpoint else { throw AuthError.notConfigured }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("AWSCognitoIdentityProviderService.\(action)", forHTTPHeaderField: "X-Amz-Target")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]

        guard let http = response as? HTTPURLResponse else { throw AuthError.malformedResponse }
        guard (200..<300).contains(http.statusCode) else {
            // Surface Cognito's user-facing message (e.g. "Incorrect username or
            // password") but nothing lower-level than that.
            let message = (json["message"] as? String) ?? "Request failed."
            throw AuthError.server(message)
        }
        return json
    }
}
