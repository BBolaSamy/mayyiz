import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

/// Service for handling analytics events and crash reporting
class AnalyticsService {
    
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - Event Types
    
    enum EventName: String {
        case scanStarted = "scan_started"
        case scanCompleted = "scan_completed"
        case scanFlagged = "scan_flagged"
        case activeScanUsed = "active_scan_used"
        case reportSent = "report_sent"
    }
    
    // MARK: - Analytics
    
    /// Log a custom event
    /// - Parameters:
    ///   - event: The event name
    ///   - parameters: Optional parameters
    func logEvent(_ event: EventName, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event.rawValue, parameters: parameters)
        print("📊 Analytics Event: \(event.rawValue) - \(parameters ?? [:])")
    }
    
    /// Set user property
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    // MARK: - Crashlytics
    
    /// Record a non-fatal error
    /// - Parameters:
    ///   - error: The error to record
    ///   - userInfo: Additional context
    func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
        print("⚠️ Crashlytics Non-Fatal: \(error.localizedDescription)")
    }
    
    /// Log a message to Crashlytics (shows in logs if a crash occurs)
    func logMessage(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    /// Set custom keys for Crashlytics context
    func setCustomKey(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
}

// MARK: - Custom Errors

enum AnalysisError: Error, LocalizedError {
    case lowConfidence(score: Double)
    
    var errorDescription: String? {
        switch self {
        case .lowConfidence(let score):
            return "OCR confidence too low: \(score)"
        }
    }
}
