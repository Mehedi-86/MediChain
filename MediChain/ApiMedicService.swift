//
//  ApiMedicService.swift
//  MediChain
//
//  Created by mehedi hasan on 11/3/26.
//

import Foundation
import CryptoKit

// MARK: - API Models
struct ApiMedicTokenResponse: Codable {
    let Token: String
}

struct ApiMedicDiagnosisResponse: Codable {
    let Issue: IssueData
    let Specialisation: [SpecialistData]
}

struct IssueData: Codable {
    let Name: String
}

struct SpecialistData: Codable {
    let Name: String
}

// MARK: - Service Class
class ApiMedicService {
    static let shared = ApiMedicService()
    
    // Auth Token cache
    private var currentToken: String?
    
    // Simple Prototype Matcher: Maps common words to ApiMedic Symptom IDs
    private let symptomDictionary: [String: Int] = [
        "headache": 9,
        "fever": 11,
        "cough": 15,
        "stomach": 14,
        "nausea": 44,
        "fatigue": 16,
        "pain": 10
    ]
    
    // 1. Generate HMAC MD5 Token
    private func fetchToken() async throws -> String {
        if let token = currentToken { return token }
        
        let authUrlString = "https://sandbox-authservice.priaid.ch/login"
        guard let urlData = authUrlString.data(using: .utf8) else { throw URLError(.badURL) }
        
        // Hash the URL using your Secret Key
        let symmetricKey = SymmetricKey(data: Data(APIKeys.apiMedicSecret.utf8))
        let signature = HMAC<Insecure.MD5>.authenticationCode(for: urlData, using: symmetricKey)
        let hashString = Data(signature).base64EncodedString()
        
        var request = URLRequest(url: URL(string: authUrlString)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIKeys.apiMedicKey):\(hashString)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ApiMedicTokenResponse.self, from: data)
        
        self.currentToken = response.Token
        return response.Token
    }
    
    // 2. Ask ApiMedic for the Doctor Type
    func suggestSpecialist(from notes: String) async throws -> String {
        let token = try await fetchToken()
        
        // Find matching symptoms from user text
        let lowercasedNotes = notes.lowercased()
        var matchedSymptomIds: [Int] = []
        
        for (keyword, id) in symptomDictionary {
            if lowercasedNotes.contains(keyword) {
                matchedSymptomIds.append(id)
            }
        }
        
        // If the user didn't type a known keyword, default to General Physician
        guard !matchedSymptomIds.isEmpty else {
            return "General practice"
        }
        
        // Format the URL with our matched IDs
        let symptomsJSON = "[\(matchedSymptomIds.map { String($0) }.joined(separator: ","))]"
        let diagnosisUrlString = "https://sandbox-healthservice.priaid.ch/diagnosis?symptoms=\(symptomsJSON)&gender=male&year_of_birth=1995&token=\(token)&language=en-gb"
        
        guard let url = URL(string: diagnosisUrlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([ApiMedicDiagnosisResponse].self, from: data)
        
        // Return the first recommended specialist
        if let firstDiagnosis = response.first, let topSpecialist = firstDiagnosis.Specialisation.first?.Name {
            return topSpecialist
        }
        
        return "General practice"
    }
}
