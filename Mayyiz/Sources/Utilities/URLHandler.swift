import Foundation

/// Handles parsing and routing of URL schemes
struct URLHandler {
    
    // MARK: - URL Parsing
    
    /// Parse incoming URL and extract route information
    /// - Parameter url: The URL to parse
    /// - Returns: URLRoute if valid, nil otherwise
    static func parse(_ url: URL) -> URLRoute? {
        guard url.scheme == "mayyiz" else {
            print("⚠️ Invalid URL scheme: \(url.scheme ?? "none")")
            return nil
        }
        
        guard let host = url.host else {
            print("⚠️ No host in URL: \(url)")
            return nil
        }
        
        print("🔗 Parsing URL - Host: \(host), Path: \(url.path)")
        
        // Parse query parameters
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce(into: [String: String]()) { result, item in
                result[item.name] = item.value
            } ?? [:]
        
        // Route based on host
        switch host.lowercased() {
        case "share":
            return parseShareRoute(queryItems: queryItems)
            
        case "profile":
            return parseProfileRoute(path: url.path, queryItems: queryItems)
            
        case "settings":
            return .settings
            
        case "dashboard":
            return .dashboard
            
        default:
            print("⚠️ Unknown route: \(host)")
            return .unknown(host)
        }
    }
    
    // MARK: - Route Parsers
    
    private static func parseShareRoute(queryItems: [String: String]) -> URLRoute {
        if let shareId = queryItems["id"] {
            print("✅ Share route with ID: \(shareId)")
            return .share(id: shareId)
        } else {
            print("⚠️ Share route without ID")
            return .shareWithoutId
        }
    }
    
    private static func parseProfileRoute(path: String, queryItems: [String: String]) -> URLRoute {
        // Extract user ID from path (e.g., /123 or /user123)
        let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        if let userId = components.first {
            return .profile(userId: userId)
        } else if let userId = queryItems["id"] {
            return .profile(userId: userId)
        } else {
            return .profileWithoutId
        }
    }
    
    // MARK: - URL Building
    
    /// Build a URL for sharing
    /// - Parameter shareId: The share ID
    /// - Returns: URL for the share route
    static func buildShareURL(shareId: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mayyiz"
        components.host = "share"
        components.queryItems = [URLQueryItem(name: "id", value: shareId)]
        return components.url
    }
    
    /// Build a URL for profile
    /// - Parameter userId: The user ID
    /// - Returns: URL for the profile route
    static func buildProfileURL(userId: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mayyiz"
        components.host = "profile"
        components.path = "/\(userId)"
        return components.url
    }
}

// MARK: - URL Route

/// Represents different URL routes in the app
enum URLRoute: Equatable {
    case share(id: String)
    case shareWithoutId
    case profile(userId: String)
    case profileWithoutId
    case settings
    case dashboard
    case unknown(String)
    
    var description: String {
        switch self {
        case .share(let id):
            return "Share with ID: \(id)"
        case .shareWithoutId:
            return "Share without ID"
        case .profile(let userId):
            return "Profile: \(userId)"
        case .profileWithoutId:
            return "Profile without ID"
        case .settings:
            return "Settings"
        case .dashboard:
            return "Dashboard"
        case .unknown(let host):
            return "Unknown route: \(host)"
        }
    }
}
