import SwiftUI

struct PreventionTipsView: View {
    var keyword: String
    
    @State private var healthTips: [HealthResource] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let apiService = HealthfinderService()
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView("Fetching prevention tips...")
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else if healthTips.isEmpty {
                    // NEW: Friendly message when the API has no data for this keyword
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No specific official tips found for '\(keyword)'.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text("Try consulting your doctor for personalized advice.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(healthTips) { tip in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(tip.title)
                                .font(.headline)
                            
                            if let url = URL(string: tip.accessibleVersion) {
                                Link("Read full advice", destination: url)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Prevention Tips")
            .task {
                await loadTips()
            }
        }
    }
    
    func loadTips() async {
        isLoading = true
        errorMessage = nil
        
        do {
            healthTips = try await apiService.fetchRecommendations(keyword: keyword)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    PreventionTipsView(keyword: "Diabetes")
}
