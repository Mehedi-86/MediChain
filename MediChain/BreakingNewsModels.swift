import Foundation
import FirebaseFirestore

struct BreakingNewsItem: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let brief: String?
    let article: String?
    let message: String?
    let createdAt: Date

    var displayBrief: String {
        let value = (brief ?? message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "No summary provided." : value
    }

    var displayArticle: String {
        let value = (article ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { return value }
        return displayBrief
    }
}
