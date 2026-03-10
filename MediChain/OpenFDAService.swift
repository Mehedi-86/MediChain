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
    
    /// Fetches official drug information from the US FDA public database
    func fetchDrugDetails(for medicineName: String) async throws -> FDADrugDetail? {
        // 1. Clean up the medicine name for the URL (e.g., "Tylenol" -> "tylenol")
        let cleanedName = medicineName.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // 2. Build the exact URL the FDA expects (searching by brand or generic name)
        let urlString = "https://api.fda.gov/drug/label.json?search=openfda.brand_name:\"\(cleanedName)\"+openfda.generic_name:\"\(cleanedName)\"&limit=1"
        
        guard let url = URL(string: urlString) else {
            print("🚨 Invalid FDA URL")
            return nil
        }
        
        // 3. Send the request (No API key needed!)
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 4. Handle "Not Found" errors gracefully (e.g., if Gemini misread the text)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
            print("⚠️ FDA Database: Medicine '\(medicineName)' not found.")
            return nil
        }
        
        // 5. Decode the JSON into our Swift Structs
        do {
            let decoder = JSONDecoder()
            let fdaResponse = try decoder.decode(FDAResponse.self, from: data)
            return fdaResponse.results.first
        } catch {
            print("🚨 Error parsing FDA JSON: \(error.localizedDescription)")
            return nil
        }
    }
}
