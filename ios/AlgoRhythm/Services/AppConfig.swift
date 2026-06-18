import Foundation

/// Backend configuration, read from an untracked `AppConfig.plist` that the
/// CDK deploy script writes out. Keeping it out of source control means the
/// AppSync endpoint and Cognito IDs aren't baked into the repo.
///
/// When the plist is absent (fresh checkout, no backend yet) the app runs in a
/// local-only mode so it still launches in the simulator.
struct AppConfig {
    let region: String
    let userPoolClientId: String
    let appSyncEndpoint: URL?

    static let shared = AppConfig.load()

    var isConfigured: Bool {
        !userPoolClientId.isEmpty
    }

    private static func load() -> AppConfig {
        guard let url = Bundle.main.url(forResource: "AppConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return AppConfig(region: "us-east-1", userPoolClientId: "", appSyncEndpoint: nil)
        }

        let region = plist["Region"] as? String ?? "us-east-1"
        let clientId = plist["UserPoolClientId"] as? String ?? ""
        let endpoint = (plist["AppSyncEndpoint"] as? String).flatMap(URL.init(string:))
        return AppConfig(region: region, userPoolClientId: clientId, appSyncEndpoint: endpoint)
    }
}
