import Foundation

/// Service for analyzing text and URLs for phishing/scam indicators
class HeuristicsService {
    
    // MARK: - URL Patterns
    
    /// Known shortlink domains
    private static let shortlinkDomains = [
        "bit.ly", "tinyurl.com", "goo.gl", "ow.ly", "t.co",
        "buff.ly", "is.gd", "cli.gs", "pic.gd", "DwarfURL.com",
        "yfrog.com", "migre.me", "ff.im", "tiny.cc", "url4.eu",
        "tr.im", "twit.ac", "su.pr", "twurl.nl", "snipurl.com",
        "short.to", "BudURL.com", "ping.fm", "post.ly", "Just.as",
        "bkite.com", "snipr.com", "fic.kr", "loopt.us", "doiop.com",
        "twitthis.com", "htxt.it", "AltURL.com", "RedirX.com", "DigBig.com",
        "short.ie", "u.mavrev.com", "kl.am", "wp.me", "rubyurl.com",
        "om.ly", "to.ly", "bit.do", "lnkd.in", "db.tt",
        "qr.ae", "adf.ly", "bitly.com", "cur.lv", "ity.im",
        "q.gs", "po.st", "bc.vc", "twitthis.com", "u.to",
        "j.mp", "buzurl.com", "cutt.us", "u.bb", "yourls.org",
        "x.co", "prettylinkpro.com", "scrnch.me", "filoops.info", "vzturl.com",
        "qr.net", "1url.com", "tweez.me", "v.gd", "tr.im",
        "link.zip", "cutt.ly", "rb.gy", "short.link"
    ]
    
    /// Risky top-level domains
    private static let riskyTLDs = [
        ".tk", ".ml", ".ga", ".cf", ".gq",  // Free TLDs
        ".top", ".xyz", ".club", ".work", ".click",
        ".link", ".download", ".stream", ".loan", ".win",
        ".bid", ".racing", ".party", ".review", ".trade",
        ".date", ".faith", ".science", ".cricket", ".accountant",
        ".men", ".webcam", ".pw", ".cc", ".ws"
    ]
    
    /// Legitimate bank domains (for impersonation detection)
    private static let legitimateBanks = [
        "alrajhibank.com.sa", "sabb.com", "riyadbank.com",
        "alinma.com", "bsf.com.sa", "bankalbilad.com",
        "alawwalbank.com", "samba.com", "banksaudifranci.com",
        "saib.com.sa", "arabianbank.com", "gulf-bank.com",
        "nbk.com", "cib.com.eg", "nbe.com.eg",
        "banquemisr.com", "alexbank.com", "qnb.com",
        "dohabank.com", "cbq.qa", "ahlibank.com.qa"
    ]
    
    // MARK: - Arabic Patterns
    
    /// Arabic urgency phrases
    private static let arabicUrgencyPhrases = [
        "عاجل", "فوري", "سريع", "الآن", "حالا",
        "خلال ساعة", "قبل منتصف الليل", "آخر فرصة", "ينتهي اليوم",
        "محدود", "لفترة محدودة", "العرض ينتهي", "اسرع",
        "لا تفوت", "فرصة العمر", "عرض حصري"
    ]
    
    /// Arabic penalty/threat phrases
    private static let arabicPenaltyPhrases = [
        "سيتم إيقاف", "سيتم تعليق", "سيتم إغلاق", "سيتم حظر",
        "غرامة", "عقوبة", "إجراء قانوني", "مخالفة",
        "تحذير نهائي", "آخر تنبيه", "إنذار", "مطلوب منك",
        "يجب عليك", "ملزم", "قانونيا", "محكمة"
    ]
    
    /// Arabic OTP/code request phrases
    private static let arabicOTPPhrases = [
        "رمز التحقق", "كود التفعيل", "الرمز السري", "رمز الأمان",
        "كلمة المرور", "الرقم السري", "كود OTP", "رمز التأكيد",
        "أدخل الرمز", "أرسل الكود", "شارك الرمز", "الكود المرسل",
        "رمز لمرة واحدة", "كود التحقق", "PIN", "رمز الدخول"
    ]
    
    /// Arabic bank impersonation phrases
    private static let arabicBankPhrases = [
        "بنك الراجحي", "البنك الأهلي", "بنك الرياض", "بنك الإنماء",
        "البنك السعودي", "مصرف", "حسابك البنكي", "بطاقتك الائتمانية",
        "الحساب الجاري", "التحويل البنكي", "رصيدك", "معاملة بنكية",
        "الخدمات المصرفية", "البنك المركزي", "ساما", "مؤسسة النقد"
    ]
    
    // MARK: - English Patterns
    
    /// English urgency phrases
    private static let englishUrgencyPhrases = [
        "urgent", "immediate", "act now", "limited time", "expires today",
        "last chance", "don't miss", "hurry", "quick", "asap",
        "within 24 hours", "before midnight", "ending soon"
    ]
    
    /// English penalty phrases
    private static let englishPenaltyPhrases = [
        "suspended", "blocked", "terminated", "penalty", "fine",
        "legal action", "violation", "final warning", "last notice",
        "required", "mandatory", "must", "obligation"
    ]
    
    /// English OTP phrases
    private static let englishOTPPhrases = [
        "verification code", "OTP", "one-time password", "security code",
        "authentication code", "PIN", "access code", "confirm code",
        "enter code", "share code", "send code"
    ]
    
    // MARK: - Analysis Methods
    
    /// Analyze text for phishing/scam indicators
    func analyze(text: String, url: String? = nil) -> HeuristicsResult {
        var redFlags: [RedFlag] = []
        var extractedURLs: [String] = []
        var shortlinks: [String] = []
        var homoglyphDomains: [String] = []
        var metadata: [String: String] = [:]
        
        // Extract URLs from text
        extractedURLs = extractURLs(from: text)
        
        // Add provided URL if any
        if let url = url, !url.isEmpty {
            extractedURLs.append(url)
        }
        
        // Analyze URLs
        for url in extractedURLs {
            let urlFlags = analyzeURL(url)
            redFlags.append(contentsOf: urlFlags.flags)
            
            if urlFlags.isShortlink {
                shortlinks.append(url)
            }
            
            if let homoglyph = urlFlags.homoglyphDomain {
                homoglyphDomains.append(homoglyph)
            }
        }
        
        // Analyze text content
        let contentFlags = analyzeContent(text)
        redFlags.append(contentsOf: contentFlags)
        
        // Guess communication channel
        let channel = guessChannel(text: text, urls: extractedURLs)
        
        // Calculate risk score
        let riskScore = calculateRiskScore(redFlags: redFlags)
        
        // Add metadata
        metadata["urlCount"] = "\(extractedURLs.count)"
        metadata["shortlinkCount"] = "\(shortlinks.count)"
        metadata["flagCount"] = "\(redFlags.count)"
        metadata["textLength"] = "\(text.count)"
        
        return HeuristicsResult(
            riskScore: riskScore,
            redFlags: Array(Set(redFlags)), // Remove duplicates
            channel: channel,
            extractedURLs: extractedURLs,
            shortlinks: shortlinks,
            homoglyphDomains: homoglyphDomains,
            metadata: metadata
        )
    }
    
    // MARK: - URL Analysis
    
    private struct URLAnalysisResult {
        var flags: [RedFlag] = []
        var isShortlink: Bool = false
        var homoglyphDomain: String? = nil
    }
    
    private func analyzeURL(_ urlString: String) -> URLAnalysisResult {
        var result = URLAnalysisResult()
        
        guard let url = URL(string: urlString.lowercased()) else {
            return result
        }
        
        // Check for shortlinks
        if let host = url.host {
            if Self.shortlinkDomains.contains(where: { host.contains($0) }) {
                result.flags.append(.shortlink)
                result.isShortlink = true
            }
            
            // Check for risky TLDs
            for tld in Self.riskyTLDs {
                if host.hasSuffix(tld) {
                    result.flags.append(.riskyTLD)
                    break
                }
            }
            
            // Check for homoglyphs
            if containsHomoglyphs(host) {
                result.flags.append(.homoglyphDomain)
                result.homoglyphDomain = host
            }
            
            // Check for IP address
            if isIPAddress(host) {
                result.flags.append(.ipAddress)
            }
            
            // Check for excessive subdomains
            let subdomainCount = host.components(separatedBy: ".").count - 2
            if subdomainCount > 3 {
                result.flags.append(.excessiveSubdomains)
            }
            
            // Check for mixed language in domain
            if containsMixedScripts(host) {
                result.flags.append(.mixedLanguageURL)
            }
        }
        
        // Check for HTTP (not HTTPS)
        if url.scheme == "http" {
            result.flags.append(.noHTTPS)
        }
        
        // Check for unusual port
        if let port = url.port, ![80, 443, 8080].contains(port) {
            result.flags.append(.unusualPort)
        }
        
        return result
    }
    
    /// Extract URLs from text
    private func extractURLs(from text: String) -> [String] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        return matches?.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        } ?? []
    }
    
    /// Check if domain contains homoglyphs
    private func containsHomoglyphs(_ domain: String) -> Bool {
        // Common homoglyph patterns
        let homoglyphs: [Character: [Character]] = [
            "a": ["а", "ạ", "ą"],  // Cyrillic а, Vietnamese ạ
            "e": ["е", "ė", "ę"],  // Cyrillic е
            "o": ["о", "ο", "ọ"],  // Cyrillic о, Greek ο
            "p": ["р", "ρ"],       // Cyrillic р, Greek ρ
            "c": ["с", "ϲ"],       // Cyrillic с, Greek ϲ
            "i": ["і", "ı", "ɪ"],  // Cyrillic і, Turkish ı
            "x": ["х", "χ"],       // Cyrillic х, Greek χ
            "y": ["у", "ү"],       // Cyrillic у
        ]
        
        for char in domain.lowercased() {
            for (_, variants) in homoglyphs {
                if variants.contains(char) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Check if string is an IP address
    private func isIPAddress(_ string: String) -> Bool {
        let ipv4Pattern = "^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$"
        let ipv6Pattern = "^(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$"
        
        let ipv4Regex = try? NSRegularExpression(pattern: ipv4Pattern)
        let ipv6Regex = try? NSRegularExpression(pattern: ipv6Pattern)
        
        let range = NSRange(string.startIndex..., in: string)
        
        return ipv4Regex?.firstMatch(in: string, range: range) != nil ||
               ipv6Regex?.firstMatch(in: string, range: range) != nil
    }
    
    /// Check if domain contains mixed scripts
    private func containsMixedScripts(_ domain: String) -> Bool {
        var hasLatin = false
        var hasArabic = false
        var hasCyrillic = false
        
        for scalar in domain.unicodeScalars {
            if ("a"..."z").contains(String(scalar)) || ("A"..."Z").contains(String(scalar)) {
                hasLatin = true
            } else if ("\u{0600}"..."\u{06FF}").contains(String(scalar)) {
                hasArabic = true
            } else if ("\u{0400}"..."\u{04FF}").contains(String(scalar)) {
                hasCyrillic = true
            }
        }
        
        let scriptCount = [hasLatin, hasArabic, hasCyrillic].filter { $0 }.count
        return scriptCount > 1
    }
    
    // MARK: - Content Analysis
    
    private func analyzeContent(_ text: String) -> [RedFlag] {
        var flags: [RedFlag] = []
        let lowerText = text.lowercased()
        
        // Check Arabic patterns
        for phrase in Self.arabicUrgencyPhrases {
            if text.contains(phrase) {
                flags.append(.arabicUrgency)
                break
            }
        }
        
        for phrase in Self.arabicPenaltyPhrases {
            if text.contains(phrase) {
                flags.append(.arabicPenalty)
                break
            }
        }
        
        for phrase in Self.arabicOTPPhrases {
            if text.contains(phrase) {
                flags.append(.arabicOTP)
                break
            }
        }
        
        for phrase in Self.arabicBankPhrases {
            if text.contains(phrase) {
                flags.append(.arabicBankImpersonation)
                break
            }
        }
        
        // Check English patterns
        for phrase in Self.englishUrgencyPhrases {
            if lowerText.contains(phrase) {
                flags.append(.urgencyPhrase)
                break
            }
        }
        
        for phrase in Self.englishPenaltyPhrases {
            if lowerText.contains(phrase) {
                flags.append(.penaltyThreat)
                break
            }
        }
        
        for phrase in Self.englishOTPPhrases {
            if lowerText.contains(phrase) {
                flags.append(.otpRequest)
                break
            }
        }
        
        // Check for password requests
        if lowerText.contains("password") || lowerText.contains("credentials") {
            flags.append(.passwordRequest)
        }
        
        // Check for account suspension
        if lowerText.contains("account") && (lowerText.contains("suspend") || lowerText.contains("lock")) {
            flags.append(.accountSuspension)
        }
        
        // Check for prize/lottery
        if lowerText.contains("winner") || lowerText.contains("prize") || lowerText.contains("lottery") {
            flags.append(.prizeWinner)
        }
        
        // Check for money transfer
        if lowerText.contains("transfer money") || lowerText.contains("send money") {
            flags.append(.moneyTransfer)
        }
        
        return flags
    }
    
    // MARK: - Channel Detection
    
    private func guessChannel(text: String, urls: [String]) -> CommunicationChannel {
        let lowerText = text.lowercased()
        
        // Check for WhatsApp indicators
        if lowerText.contains("whatsapp") || lowerText.contains("واتساب") {
            return .whatsapp
        }
        
        // Check for email indicators
        if lowerText.contains("@") || lowerText.contains("email") || lowerText.contains("بريد") {
            return .email
        }
        
        // Check for SMS indicators (short text, no complex formatting)
        if text.count < 160 && !text.contains("\n\n") {
            return .sms
        }
        
        // Check for social media
        if urls.contains(where: { url in
            url.contains("facebook") || url.contains("twitter") ||
            url.contains("instagram") || url.contains("tiktok")
        }) {
            return .socialMedia
        }
        
        return .unknown
    }
    
    // MARK: - Risk Calculation
    
    private func calculateRiskScore(redFlags: [RedFlag]) -> Int {
        let totalSeverity = redFlags.reduce(0) { $0 + $1.severity }
        
        // Cap at 100
        return min(100, totalSeverity)
    }
}
