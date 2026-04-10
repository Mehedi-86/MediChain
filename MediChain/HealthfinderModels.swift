import Foundation

// These structs match the nested JSON structure of the MyHealthfinder API
struct HealthfinderResponse: Codable {
    let result: HealthResult
    
    enum CodingKeys: String, CodingKey {
        case result = "Result"
    }
}

struct HealthResult: Codable {
    let resources: ResourceContainer
    
    enum CodingKeys: String, CodingKey {
        case resources = "Resources"
    }
}

struct ResourceContainer: Codable {
    let resourceList: [HealthResource]
    
    enum CodingKeys: String, CodingKey {
        case resourceList = "Resource"
    }
}

struct HealthResource: Codable, Identifiable {
    let id: String
    let title: String
    let accessibleVersion: String // URL to the full article
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case title = "Title"
        case accessibleVersion = "AccessibleVersion"
    }
}
