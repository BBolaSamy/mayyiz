import Foundation

/// Red flag types for security analysis
enum RedFlag: String, Codable, Equatable {
    // URL-based flags
    case shortlink = "shortlink"
    case homoglyphDomain = "homoglyph_domain"
    case riskyTLD = "risky_tld"
    case suspiciousURL = "suspicious_url"
    case ipAddress = "ip_address"
    case excessiveSubdomains = "excessive_subdomains"
    
    // Content-based flags
    case urgencyPhrase = "urgency_phrase"
    case penaltyThreat = "penalty_threat"
    case otpRequest = "otp_request"
    case bankImpersonation = "bank_impersonation"
    case passwordRequest = "password_request"
    case accountSuspension = "account_suspension"
    case prizeWinner = "prize_winner"
    case moneyTransfer = "money_transfer"
    
    // Language-specific
    case arabicUrgency = "arabic_urgency"
    case arabicPenalty = "arabic_penalty"
    case arabicOTP = "arabic_otp"
    case arabicBankImpersonation = "arabic_bank_impersonation"
    
    // Technical flags
    case mixedLanguageURL = "mixed_language_url"
    case unusualPort = "unusual_port"
    case noHTTPS = "no_https"
    
    var severity: Int {
        switch self {
        case .homoglyphDomain, .bankImpersonation, .arabicBankImpersonation, .otpRequest, .passwordRequest:
            return 30
        case .riskyTLD, .urgencyPhrase, .penaltyThreat, .accountSuspension, .arabicUrgency, .arabicPenalty:
            return 20
        case .shortlink, .suspiciousURL, .arabicOTP, .prizeWinner, .moneyTransfer:
            return 15
        case .ipAddress, .excessiveSubdomains, .mixedLanguageURL, .noHTTPS:
            return 10
        case .unusualPort:
            return 5
        }
    }
    
    var description: String {
        switch self {
        case .shortlink:
            return "URL shortener detected"
        case .homoglyphDomain:
            return "Domain uses look-alike characters"
        case .riskyTLD:
            return "Suspicious top-level domain"
        case .suspiciousURL:
            return "URL contains suspicious patterns"
        case .ipAddress:
            return "URL uses IP address instead of domain"
        case .excessiveSubdomains:
            return "Too many subdomains"
        case .urgencyPhrase:
            return "Urgency language detected"
        case .penaltyThreat:
            return "Penalty or threat language"
        case .otpRequest:
            return "Requests one-time password"
        case .bankImpersonation:
            return "Possible bank impersonation"
        case .passwordRequest:
            return "Requests password or credentials"
        case .accountSuspension:
            return "Account suspension threat"
        case .prizeWinner:
            return "Prize or lottery claim"
        case .moneyTransfer:
            return "Money transfer request"
        case .arabicUrgency:
            return "Arabic urgency phrase detected"
        case .arabicPenalty:
            return "Arabic penalty threat"
        case .arabicOTP:
            return "Arabic OTP request"
        case .arabicBankImpersonation:
            return "Arabic bank impersonation"
        case .mixedLanguageURL:
            return "URL mixes multiple scripts"
        case .unusualPort:
            return "Non-standard port number"
        case .noHTTPS:
            return "Insecure HTTP connection"
        }
    }
}

/// Communication channel guess
enum CommunicationChannel: String, Codable, Equatable {
    case sms = "sms"
    case email = "email"
    case whatsapp = "whatsapp"
    case socialMedia = "social_media"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .sms:
            return "SMS/Text Message"
        case .email:
            return "Email"
        case .whatsapp:
            return "WhatsApp"
        case .socialMedia:
            return "Social Media"
        case .unknown:
            return "Unknown Channel"
        }
    }
}

/// Result of heuristics analysis
struct HeuristicsResult: Codable, Equatable {
    /// Preliminary risk score (0-100)
    let riskScore: Int
    
    /// List of detected red flags
    let redFlags: [RedFlag]
    
    /// Guessed communication channel
    let channel: CommunicationChannel
    
    /// Extracted URLs
    let extractedURLs: [String]
    
    /// Detected shortlinks
    let shortlinks: [String]
    
    /// Detected homoglyph domains
    let homoglyphDomains: [String]
    
    /// Additional metadata
    let metadata: [String: String]
    
    init(riskScore: Int,
         redFlags: [RedFlag] = [],
         channel: CommunicationChannel = .unknown,
         extractedURLs: [String] = [],
         shortlinks: [String] = [],
         homoglyphDomains: [String] = [],
         metadata: [String: String] = [:]) {
        self.riskScore = min(100, max(0, riskScore))
        self.redFlags = redFlags
        self.channel = channel
        self.extractedURLs = extractedURLs
        self.shortlinks = shortlinks
        self.homoglyphDomains = homoglyphDomains
        self.metadata = metadata
    }
    
    /// Get risk level description
    var riskLevel: String {
        switch riskScore {
        case 0..<20:
            return "Low"
        case 20..<50:
            return "Medium"
        case 50..<80:
            return "High"
        default:
            return "Critical"
        }
    }
    
    /// Check if result indicates high risk
    var isHighRisk: Bool {
        return riskScore >= 50
    }
}
