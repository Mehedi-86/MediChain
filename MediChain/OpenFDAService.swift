//
//  OpenFDAService.swift
//  MediChain
//
//  Created by mehedi hasan on 10/3/26.
//

import Foundation

// MARK: - JSON Models
// These structs tell Swift exactly how to read the FDA's JSON response
struct FDAResponse: Codable {
    let results: [FDADrugDetail]
}

struct FDAErrorResponse: Codable {
    struct APIError: Codable {
        let code: String
        let message: String
    }

    let error: APIError
}

struct FDADrugDetail: Codable {
    let purpose: [String]?
    let warnings: [String]?
    let dosageAndAdministration: [String]?
    
    // This maps the ugly JSON keys to clean Swift variable names
    enum CodingKeys: String, CodingKey {
        case purpose
        case warnings
        case dosageAndAdministration = "dosage_and_administration"
    }
}

// MARK: - API Service
class OpenFDAService {
    static let shared = OpenFDAService()
    private let baseURL = "https://api.fda.gov/drug/label.json"
    
    /// Fetches official drug information from the US FDA public database
    func fetchDrugDetails(for medicineName: String) async throws -> FDADrugDetail? {
        let trimmedName = medicineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        // Try a few query terms because OCR/Gemini can include dosage text (e.g. "paracetamol 500mg").
        let queryTerms = buildCandidateTerms(from: trimmedName)
        print("[OpenFDA] Search terms: \(queryTerms.joined(separator: " | "))")

        for term in queryTerms {
            guard let url = buildSearchURL(for: term) else {
                continue
            }

            print("[OpenFDA] Trying term: \(term)")

            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                continue
            }

            switch httpResponse.statusCode {
            case 200:
                do {
                    let fdaResponse = try JSONDecoder().decode(FDAResponse.self, from: data)
                    if let first = fdaResponse.results.first {
                        print("[OpenFDA] Match found with term: \(term)")
                        return first
                    }
                } catch {
                        print("[OpenFDA] Error parsing JSON for '\(term)': \(error.localizedDescription)")
                }

            case 404:
                // "No matches found" is normal for a given term; move to next fallback.
                continue

            case 429:
                if let apiMessage = decodeAPIErrorMessage(from: data) {
                        print("[OpenFDA] Rate limit hit: \(apiMessage)")
                } else {
                        print("[OpenFDA] Rate limit hit (429).")
                }
                return nil

            default:
                if let apiMessage = decodeAPIErrorMessage(from: data) {
                        print("[OpenFDA] Request failed (\(httpResponse.statusCode)): \(apiMessage)")
                } else {
                        print("[OpenFDA] Request failed with status \(httpResponse.statusCode).")
                }
            }
        }

            print("[OpenFDA] Medicine '\(medicineName)' not found.")
        return nil
    }

    private func buildCandidateTerms(from rawName: String) -> [String] {
        let compact = normalizeSpaces(rawName)
        let strippedDosage = stripDosageUnits(from: compact)
        let alphabeticOnly = keepAlphabeticWords(from: strippedDosage)

        let firstToken = alphabeticOnly
            .components(separatedBy: " ")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var orderedTerms: [String] = []
        orderedTerms.append(compact)

        if !strippedDosage.isEmpty, strippedDosage.caseInsensitiveCompare(compact) != .orderedSame {
            orderedTerms.append(strippedDosage)
        }

        if !alphabeticOnly.isEmpty, alphabeticOnly.caseInsensitiveCompare(strippedDosage) != .orderedSame {
            orderedTerms.append(alphabeticOnly)
        }

        if let firstToken, firstToken.count > 2 {
            orderedTerms.append(firstToken)
        }

        return dedupePreservingOrder(orderedTerms)
    }

    private func normalizeSpaces(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stripDosageUnits(from text: String) -> String {
        // Examples removed: "500mg", "5 ml", "250 mcg", "10%"
        let dosagePattern = "\\b\\d+(?:[.,]\\d+)?(?:/\\d+(?:[.,]\\d+)?)?\\s*(?:mg|mcg|g|kg|ml|l|iu|units?|%)\\b"
        let withoutDosage = text.replacingOccurrences(of: dosagePattern, with: " ", options: .regularExpression)
        return normalizeSpaces(withoutDosage)
    }

    private func keepAlphabeticWords(from text: String) -> String {
        let cleaned = text.replacingOccurrences(of: "[^a-zA-Z\\s-]", with: " ", options: .regularExpression)
        return normalizeSpaces(cleaned)
    }

    private func dedupePreservingOrder(_ terms: [String]) -> [String] {
        var seen: Set<String> = []
        var output: [String] = []

        for term in terms {
            let normalized = term.lowercased()
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            seen.insert(normalized)
            output.append(term)
        }

        return output
    }

    private func buildSearchURL(for term: String) -> URL? {
        let searchQuery = "(openfda.brand_name:\"\(term)\" OR openfda.generic_name:\"\(term)\" OR openfda.substance_name:\"\(term)\")"

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "search", value: searchQuery),
            URLQueryItem(name: "limit", value: "1")
        ]

        return components?.url
    }

    private func decodeAPIErrorMessage(from data: Data) -> String? {
        guard let errorResponse = try? JSONDecoder().decode(FDAErrorResponse.self, from: data) else {
            return nil
        }

        return errorResponse.error.message
    }
}