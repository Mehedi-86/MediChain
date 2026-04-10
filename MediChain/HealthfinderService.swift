import Foundation

class HealthfinderService {
    
    func fetchRecommendations(keyword: String) async throws -> [HealthResource] {
        
        // 1. Clean the text (remove extra spaces and make it lowercase)
        let searchWord = keyword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Encode the keyword so it safely fits in a URL (e.g., turns "heart disease" into "heart%20disease")
        guard let safeKeyword = searchWord.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://odphp.health.gov/myhealthfinder/api/v4/topicsearch.json?keyword=\(safeKeyword)") else {
            throw URLError(.badURL)
        }
        
        // 3. Make the network request to the dynamic search API
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 4. Handle the "Not Found" reality mentioned in the PDF.
        // If the API doesn't recognize the word, just return an empty list gracefully.
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        // 5. Decode the JSON
        do {
            let decodedResponse = try JSONDecoder().decode(HealthfinderResponse.self, from: data)
            return decodedResponse.result.resources.resourceList
        } catch {
            // If the JSON structure is empty or fails to parse, return empty
            return []
        }
    }
}
