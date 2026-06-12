import Foundation
import os

// MARK: - Response Model

struct CreelCatchSummary: Identifiable, Codable {
    let id: String
    let waterBody: String
    let catchAreaCode: String
    let totalHatch: Int
    let totalWild: Int
    let totalWildReleased: Int
    let totalHatchReleased: Int
    let totalAnglers: Int
    var sectionDescription: String? = nil   // filled in by WDFWCreelService

    var totalCatch: Int { totalHatch + totalWild + totalWildReleased + totalHatchReleased }
    var totalHarvest: Int { totalHatch + totalWild }

    // Normalized 0-1 across the result set (set externally after fetching)
    var normalizedScore: Double = 0

    enum CodingKeys: String, CodingKey {
        case waterBody           = "water_body"
        case catchAreaCode       = "catch_area_code"
        case totalHatch          = "total_hatch"
        case totalWild           = "total_wild"
        case totalWildReleased   = "total_w_released"
        case totalHatchReleased  = "total_h_released"
        case totalAnglers        = "total_anglers"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        waterBody          = try c.decode(String.self, forKey: .waterBody)
        catchAreaCode      = try c.decode(String.self, forKey: .catchAreaCode)
        totalHatch         = Int(try c.decodeIfPresent(String.self, forKey: .totalHatch) ?? "0") ?? 0
        totalWild          = Int(try c.decodeIfPresent(String.self, forKey: .totalWild) ?? "0") ?? 0
        totalWildReleased  = Int(try c.decodeIfPresent(String.self, forKey: .totalWildReleased) ?? "0") ?? 0
        totalHatchReleased = Int(try c.decodeIfPresent(String.self, forKey: .totalHatchReleased) ?? "0") ?? 0
        totalAnglers       = Int(try c.decodeIfPresent(String.self, forKey: .totalAnglers) ?? "0") ?? 0
        id = "\(catchAreaCode)-\(waterBody)"
    }
}

// MARK: - Section Description DTO (from vkjc-s5u8)

private struct FisheryManagerDTO: Decodable {
    let catchAreaCode: String?
    let catchAreaDescription: String?

    enum CodingKeys: String, CodingKey {
        case catchAreaCode        = "catch_area_code"
        case catchAreaDescription = "catch_area_description"
    }
}

// MARK: - Service

actor WDFWCreelService {
    private let logger = Logger(subsystem: "com.appsonapps.fishyfriendguide", category: "WDFWCreelService")
    private let summaryURL   = "https://data.wa.gov/resource/dpqw-kc2b.json"
    private let fisheryMgrURL = "https://data.wa.gov/resource/vkjc-s5u8.json"

    /// Section descriptions keyed by catch_area_code (lazy loaded once)
    private var sectionDescriptions: [String: String] = [:]

    /// Cached results keyed by week range string
    private var cache: [String: (results: [CreelCatchSummary], fetchedAt: Date)] = [:]
    private let cacheTTL: TimeInterval = 6 * 60 * 60  // 6 hours

    // MARK: - Public

    /// Historical catch for a ±windowWeeks window around `date`'s week-of-year,
    /// aggregated across all available years. Annotates each result with its section description.
    func fetchWeeklyCatch(for date: Date = Date(), windowWeeks: Int = 2) async throws -> [CreelCatchSummary] {
        let calendar = Calendar(identifier: .gregorian)
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let startWeek  = max(1, weekOfYear - windowWeeks)
        let endWeek    = min(52, weekOfYear + windowWeeks)
        let cacheKey   = "\(startWeek)-\(endWeek)"

        if let cached = cache[cacheKey], Date().timeIntervalSince(cached.fetchedAt) < cacheTTL {
            logger.debug("Cache hit for weeks \(startWeek)-\(endWeek)")
            return cached.results
        }

        // Lazy-load section descriptions
        if sectionDescriptions.isEmpty {
            try? await loadSectionDescriptions()
        }

        var results = try await fetch(startWeek: startWeek, endWeek: endWeek)

        // Annotate with section descriptions
        for i in results.indices {
            results[i].sectionDescription = sectionDescriptions[results[i].catchAreaCode]
        }

        cache[cacheKey] = (results, Date())
        return results
    }

    /// Yearly trend (all weeks) for a specific river section.
    func fetchYearlyTrend(waterbody: String, catchAreaCode: String) async throws -> [WeeklyTrendPoint] {
        var components = URLComponents(string: summaryURL)!
        let q = "water_body='\(waterbody)' AND catch_area_code='\(catchAreaCode)' AND species_name in ('Steelhead','Chinook','Coho','Pink')"
        components.queryItems = [
            .init(name: "$select", value: "date_extract_woy(survey_date) as week_num,sum(hatchery_harvest) as total_hatch,sum(wild_harvest) as total_wild,sum(wild_released) as total_w_released,sum(hatchery_released) as total_h_released"),
            .init(name: "$where",  value: q),
            .init(name: "$group",  value: "week_num"),
            .init(name: "$order",  value: "week_num ASC"),
            .init(name: "$limit",  value: "52"),
        ]
        guard let url = components.url else { throw CreelServiceError.badURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([WeeklyTrendDTO].self, from: data).map { $0.toPoint() }
    }

    // MARK: - Private

    private func fetch(startWeek: Int, endWeek: Int) async throws -> [CreelCatchSummary] {
        var components = URLComponents(string: summaryURL)!
        let whereClause = "date_extract_woy(survey_date) between \(startWeek) and \(endWeek) AND species_name in ('Steelhead','Chinook','Coho','Pink')"
        components.queryItems = [
            .init(name: "$select", value: "water_body,catch_area_code,sum(hatchery_harvest) as total_hatch,sum(wild_harvest) as total_wild,sum(wild_released) as total_w_released,sum(hatchery_released) as total_h_released,sum(anglers) as total_anglers"),
            .init(name: "$where",  value: whereClause),
            .init(name: "$group",  value: "water_body,catch_area_code"),
            .init(name: "$order",  value: "total_hatch DESC"),
            .init(name: "$limit",  value: "200"),
        ]
        guard let url = components.url else { throw CreelServiceError.badURL }
        logger.debug("Fetching weekly catch: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw CreelServiceError.httpError }

        var summaries = try JSONDecoder().decode([CreelCatchSummary].self, from: data)
        let maxCatch = Double(summaries.map(\.totalCatch).max() ?? 1)
        if maxCatch > 0 {
            for i in summaries.indices {
                summaries[i].normalizedScore = Double(summaries[i].totalCatch) / maxCatch
            }
        }
        logger.info("Fetched \(summaries.count) river sections for weeks \(startWeek)-\(endWeek)")
        return summaries
    }

    private func loadSectionDescriptions() async throws {
        var components = URLComponents(string: fisheryMgrURL)!
        components.queryItems = [
            .init(name: "$select", value: "distinct catch_area_code,catch_area_description"),
            .init(name: "$where",  value: "catch_area_code IS NOT NULL"),
            .init(name: "$limit",  value: "500"),
        ]
        guard let url = components.url else { return }
        let (data, _) = try await URLSession.shared.data(from: url)
        let dtos = try JSONDecoder().decode([FisheryManagerDTO].self, from: data)
        for dto in dtos {
            if let code = dto.catchAreaCode, let desc = dto.catchAreaDescription {
                sectionDescriptions[code] = desc
            }
        }
        logger.info("Loaded \(self.sectionDescriptions.count) section descriptions")
    }
}

// MARK: - Supporting Types

struct WeeklyTrendPoint: Identifiable {
    let id = UUID()
    let weekOfYear: Int
    let totalCatch: Int
    let totalHarvest: Int
}

private struct WeeklyTrendDTO: Decodable {
    let weekNum: String
    let totalHatch: String?
    let totalWild: String?
    let totalWReleased: String?
    let totalHReleased: String?

    enum CodingKeys: String, CodingKey {
        case weekNum = "week_num"
        case totalHatch = "total_hatch"
        case totalWild = "total_wild"
        case totalWReleased = "total_w_released"
        case totalHReleased = "total_h_released"
    }

    func toPoint() -> WeeklyTrendPoint {
        let h  = Int(totalHatch ?? "0") ?? 0
        let w  = Int(totalWild ?? "0") ?? 0
        let wr = Int(totalWReleased ?? "0") ?? 0
        let hr = Int(totalHReleased ?? "0") ?? 0
        return WeeklyTrendPoint(weekOfYear: Int(weekNum) ?? 0, totalCatch: h+w+wr+hr, totalHarvest: h+w)
    }
}

enum CreelServiceError: Error {
    case badURL, httpError
}

