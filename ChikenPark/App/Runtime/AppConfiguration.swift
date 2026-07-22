import Foundation

enum AppConfiguration {
    static let expectedBundleID = "app.featherwind"
    static let privacyPolicyURL = SkyFarmAppLinks.privacyPolicy

    static var appsFlyerDevKey: String? {
        configuredString(forInfoDictionaryKey: "AppsFlyerDevKey")
    }

    static var appleAppID: String? {
        configuredString(forInfoDictionaryKey: "AppleAppID")
    }

    static var storeID: String? {
        guard let value = configuredString(forInfoDictionaryKey: "AppStoreID") else {
            return nil
        }

        return value.hasPrefix("id") ? value : nil
    }

    static var siteURL: URL? {
        configuredURL(forInfoDictionaryKey: "SiteURL")
    }

    static var supportURL: URL? {
        configuredURL(forInfoDictionaryKey: "SupportURL")
    }

    static var configURL: URL? {
        configuredURL(forInfoDictionaryKey: "ConfigURL")
    }

    static var bundleID: String {
        Bundle.main.bundleIdentifier ?? expectedBundleID
    }

    static var firebaseProjectID: String? {
        firebaseConfiguration?["PROJECT_ID"] as? String
    }

    static var firebaseProjectNumber: String? {
        firebaseConfiguration?["GCM_SENDER_ID"] as? String
    }

    static var hasFirebaseConfiguration: Bool {
        guard
            let firebaseConfiguration,
            firebaseConfiguration["BUNDLE_ID"] as? String == bundleID,
            let googleAppID = firebaseConfiguration["GOOGLE_APP_ID"] as? String,
            !googleAppID.isEmpty,
            let projectID = firebaseConfiguration["PROJECT_ID"] as? String,
            !projectID.isEmpty,
            let projectNumber = firebaseConfiguration["GCM_SENDER_ID"] as? String,
            !projectNumber.isEmpty
        else {
            return false
        }

        return true
    }

    static var hasAppsFlyerConfiguration: Bool {
        appsFlyerDevKey != nil && appleAppID != nil
    }

    static var hasConfigEndpointConfiguration: Bool {
        configURL != nil && storeID != nil
    }

    private static let firebaseConfiguration: [String: Any]? = {
        guard
            let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        else {
            return nil
        }

        return object as? [String: Any]
    }()

    private static func configuredString(forInfoDictionaryKey key: String) -> String? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !rawValue.contains("$(")
        else {
            return nil
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func configuredURL(forInfoDictionaryKey key: String) -> URL? {
        guard
            let value = configuredString(forInfoDictionaryKey: key),
            let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host != nil
        else {
            return nil
        }

        return url
    }
}
