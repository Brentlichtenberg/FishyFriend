import Foundation
import os

// MARK: - Model

struct EmergencyRule: Identifiable, Codable {
    let id: String
    let title: String
    let url: String
    let fetchedAt: Date
}

// MARK: - Service

actor EmergencyRulesService {
    private let logger = Logger(subsystem: "com.appsonapps.fishyfriendguide", category: "EmergencyRulesService")
    private let pageURL = "https://wdfw.wa.gov/fishing/regulations/emergency-rules"
    private let cacheKey = "emergencyRulesCache"
    private let fetchedAtKey = "emergencyRulesFetchedAt"

    // MARK: - Public

    /// Returns cached rules immediately, then fetches fresh data if the cache is stale (>7 days).
    func fetchRules(forceRefresh: Bool = false) async throws -> [EmergencyRule] {
        if !forceRefresh, let cached = loadCache(), !isCacheStale(cached) {
            logger.debug("Cache hit: \(cached.count) emergency rules")
            return cached
        }
        return try await fetchFromWeb()
    }

    /// Whether today is Saturday — the weekly refresh trigger.
    static func isSaturday() -> Bool {
        Calendar.current.component(.weekday, from: Date()) == 7
    }

    // MARK: - Private

    private func fetchFromWeb() async throws -> [EmergencyRule] {
        guard let url = URL(string: pageURL) else { throw EmergencyRulesError.badURL }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw EmergencyRulesError.httpError
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw EmergencyRulesError.parseError
        }

        let rules = parseRules(from: html)
        logger.info("Fetched \(rules.count) emergency rules from WDFW")
        saveCache(rules)
        return rules
    }

    /// Extracts rule titles and URLs from the WDFW emergency rules page HTML.
    /// The page renders rule list items like:
    ///   <a href="/fishing/regulations/emergency-rules/some-rule-slug" hreflang="en">Rule Title</a>
    private func parseRules(from html: String) -> [EmergencyRule] {
        var rules: [EmergencyRule] = []
        let base = "https://wdfw.wa.gov"
        let prefix = "/fishing/regulations/emergency-rules/"

        // Find all anchor tags pointing to individual rule pages
        // Pattern: href="/fishing/regulations/emergency-rules/something" ... >Title</a>
        var searchRange = html.startIndex..<html.endIndex
        while let hrefRange = html.range(of: "href=\"\(prefix)", range: searchRange) {
            // Extract the href value
            let afterHref = hrefRange.upperBound
            guard let closeQuote = html[afterHref...].firstIndex(of: "\"") else { break }
            let slug = String(html[afterHref..<closeQuote])

            // Skip if it's just the root emergency-rules page (no slug) or a hash
            guard !slug.isEmpty, !slug.hasPrefix("#"), slug != prefix else {
                searchRange = closeQuote..<html.endIndex
                continue
            }

            // Find the > after attributes, then extract text content until </a>
            guard let openAngle = html[closeQuote...].firstIndex(of: ">") else { break }
            let afterAngle = html.index(after: openAngle)
            guard let closeTag = html[afterAngle...].range(of: "</a>") else { break }
            let rawTitle = String(html[afterAngle..<closeTag.lowerBound])

            // Clean HTML entities and whitespace
            let title = rawTitle
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&ndash;", with: "–")
                .replacingOccurrences(of: "&#39;", with: "'")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !title.isEmpty else {
                searchRange = closeTag.upperBound..<html.endIndex
                continue
            }

            let fullURL = base + prefix + slug
            let id = slug.components(separatedBy: "/").last ?? slug
            rules.append(EmergencyRule(id: id, title: title, url: fullURL, fetchedAt: Date()))

            searchRange = closeTag.upperBound..<html.endIndex
        }

        // Deduplicate by id (same rule can appear multiple times due to anchors)
        var seen = Set<String>()
        return rules.filter { seen.insert($0.id).inserted }
    }

    // MARK: - Cache (UserDefaults)

    private func loadCache() -> [EmergencyRule]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let rules = try? JSONDecoder().decode([EmergencyRule].self, from: data) else {
            return nil
        }
        return rules
    }

    private func saveCache(_ rules: [EmergencyRule]) {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: fetchedAtKey)
    }

    private func isCacheStale(_ rules: [EmergencyRule]) -> Bool {
        guard let fetchedAt = UserDefaults.standard.object(forKey: fetchedAtKey) as? Date else {
            return true
        }
        // Stale after 7 days
        return Date().timeIntervalSince(fetchedAt) > 7 * 24 * 60 * 60
    }
}

enum EmergencyRulesError: Error {
    case badURL, httpError, parseError
}
