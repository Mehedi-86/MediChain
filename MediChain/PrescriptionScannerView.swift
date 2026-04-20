//
//  PrescriptionScannerView.swift
//  MediChain
//
//  Created by mehedi hasan on 7/3/26.
//

import SwiftUI

private struct FDASearchResult: Identifiable {
    let id = UUID()
    let medicineName: String
    let details: FDADrugDetail
}

struct PrescriptionScannerView: View {
    @State private var isShowingScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var extractedText: String = ""
    @State private var isProcessing = false
    @State private var isPulsing = false // Drives the offline OCR loading animation
    
    // MUBIN'S ADDITION: Drives the Gemini AI loading animation
    @State private var isCleaningText = false
    
    // NEW: FDA Feature State Variables
    @State private var fdaDetails: FDADrugDetail?
    @State private var isFetchingFDA = false
    @State private var searchedMedicineName: String = "" // Added this to hold the dynamic name!
    @State private var fdaSearchResults: [FDASearchResult] = []
    @State private var manualMedicineSearch: String = ""
    @State private var isManualFDASearching = false
    @State private var manualFDASearchError: String?
    
    // NEW: Healthfinder State Variables
    @State private var extractedDiagnosis: String = ""
    @State private var manualSearchKeyword: String = ""
    @State private var isShowingHealthTips = false
    
    // NEW: PDF Export State Variable
    @State private var pdfURL: URL?
    
    // The invisible "brain" for offline OCR
    let textRecognizer = TextRecognizer()
    
    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Premium Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(UIColor.systemGroupedBackground), Color.teal.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Beautiful Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .teal.opacity(0.4), radius: 10, x: 0, y: 5)
                                Image(systemName: "text.viewfinder")
                                    .font(.system(size: 35, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 8)
                            
                            Text("Smart Scanner")
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.heavy)
                                .foregroundStyle(LinearGradient(colors: [.teal, .blue], startPoint: .leading, endPoint: .trailing))
                            
                            Text("Instantly digitize medical documents using advanced AI text extraction.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 20)
                        
                        // MARK: - Main Action Button
                        Button(action: {
                            isShowingScanner = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.filters")
                                    .font(.title2)
                                Text("Scan Document")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [.teal, .cyan], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .teal.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        
                        // MARK: - AI Results Card
                        if isProcessing || !extractedText.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                // Card Header
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .foregroundColor(.teal)
                                    Text("Extracted Data")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if isProcessing || isCleaningText {
                                        ProgressView()
                                            .tint(.teal)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                
                                Divider()
                                
                                // Card Body (Text)
                                ScrollView {
                                    if isProcessing {
                                        VStack(spacing: 12) {
                                            ProgressView()
                                                .scaleEffect(1.5)
                                                .padding(.bottom, 8)
                                            Text("Apple Vision is scanning...")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .opacity(isPulsing ? 0.5 : 1.0)
                                                .onAppear {
                                                    withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                                                        isPulsing.toggle()
                                                    }
                                                }
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 150)
                                    } else {
                                        Text(extractedText)
                                            .font(.system(.callout, design: .monospaced))
                                            .lineSpacing(6)
                                            .foregroundColor(.primary)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .frame(maxHeight: 400) // Limits height so it scrolls if too long
                                .background(Color(UIColor.tertiarySystemGroupedBackground))
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.teal.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .bottom))) // Smooth entrance
                        }
                        
                        // MARK: - Gemini AI Button
                        if !extractedText.isEmpty && !isProcessing {
                            Button(action: {
                                Task {
                                    await cleanTextWithGemini()
                                }
                            }) {
                                HStack {
                                    if isCleaningText {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 5)
                                        Text("Gemini is Analyzing...")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    } else {
                                        Text("Clean with Gemini AI")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Image(systemName: "sparkles")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isCleaningText ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: isCleaningText ? .clear : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isCleaningText) // Prevents spam-clicking
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                        
                        // MARK: - FDA Official Information Card
                        if isFetchingFDA {
                            VStack {
                                ProgressView("Fetching official FDA data...")
                                    .padding()
                            }
                        } else if !fdaSearchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Official FDA Information")
                                    .font(.headline)
                                    .padding(.horizontal, 28)

                                ForEach(fdaSearchResults) { result in
                                    FDAInfoCard(drugDetails: result.details, medicineName: result.medicineName)
                                        .padding(.horizontal, 24)
                                }
                            }
                            .padding(.top, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // MARK: - Optional Manual Medicine Search
                        if !extractedText.isEmpty && !isProcessing {
                            VStack(spacing: 12) {
                                Text("Search Any Medicine (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 28)

                                HStack {
                                    Image(systemName: "pills.fill")
                                        .foregroundColor(.gray)
                                    TextField("Enter medicine name (e.g., Paracetamol)", text: $manualMedicineSearch)
                                        .font(.body)

                                    if !manualMedicineSearch.isEmpty {
                                        Button(action: { manualMedicineSearch = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray.opacity(0.5))
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal, 24)

                                Button(action: {
                                    Task { await searchManualMedicineFDA() }
                                }) {
                                    HStack {
                                        if isManualFDASearching {
                                            ProgressView()
                                                .tint(.white)
                                        }
                                        Image(systemName: "cross.case.fill")
                                        Text("Search FDA for This Medicine")
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(manualMedicineSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isManualFDASearching ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .disabled(manualMedicineSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isManualFDASearching)
                                .padding(.horizontal, 24)

                                if let error = manualFDASearchError {
                                    Text(error)
                                        .font(.footnote)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 28)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // MARK: - Healthfinder Search Box & Button
                        if !extractedText.isEmpty && !isProcessing {
                            VStack(spacing: 12) {
                                Text("Search Health Tips")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 28)
                                
                                // 1. The Editable Text Box
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    TextField("Enter condition (e.g., Diabetes)", text: $manualSearchKeyword)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    // Clear button if text isn't empty
                                    if !manualSearchKeyword.isEmpty {
                                        Button(action: { manualSearchKeyword = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray.opacity(0.5))
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal, 24)
                                
                                // 2. The Search Button
                                Button(action: {
                                    isShowingHealthTips = true
                                }) {
                                    HStack {
                                        Image(systemName: "heart.text.square.fill")
                                            .font(.title2)
                                        Text(manualSearchKeyword.isEmpty ? "Search Prevention Tips" : "Tips for \(manualSearchKeyword)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: manualSearchKeyword.isEmpty ? [.gray, .gray.opacity(0.8)] : [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: manualSearchKeyword.isEmpty ? .clear : .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .disabled(manualSearchKeyword.isEmpty) // Prevent empty searches
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // MARK: - Export PDF Button
                        if !extractedText.isEmpty && !isProcessing {
                            Button(action: {
                                // Generate the PDF on the main thread
                                Task {
                                    @MainActor in
                                    self.pdfURL = PDFGenerator.generateReport(
                                        extractedText: extractedText,
                                        fdaDetails: fdaDetails,
                                        medicineName: searchedMedicineName
                                    )
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Generate PDF Report")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            
                            // If the PDF is ready, show the iOS Share Link automatically
                            if let validURL = pdfURL {
                                ShareLink(item: validURL, message: Text("Here is my medical report from MediChain.")) {
                                    Label("Tap here to Share / Save PDF", systemImage: "doc.text.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            }
                        }
                        
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingScanner) {
                ScannerView(scannedImages: $scannedImages)
            }
            .sheet(isPresented: $isShowingHealthTips) {
                PreventionTipsView(keyword: manualSearchKeyword)
            }
            .onChange(of: scannedImages) { newImages in
                guard let firstImage = newImages.first else { return }
                processImage(firstImage)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Apple Vision OCR Processing
    private func processImage(_ image: UIImage) {
        withAnimation(.spring()) {
            isProcessing = true
            extractedText = ""
            fdaDetails = nil // Reset the FDA card when a new scan starts
            fdaSearchResults = []
            searchedMedicineName = ""
            manualMedicineSearch = ""
            manualFDASearchError = nil
            extractedDiagnosis = "" // Reset diagnosis when new scan starts
            manualSearchKeyword = "" // Reset manual search when new scan starts
            pdfURL = nil // Reset the PDF url so it doesn't share the old one
        }
        
        textRecognizer.recognizeText(from: image) { result in
            withAnimation(.spring()) {
                self.extractedText = result
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Gemini AI & OpenFDA Processing
    private func cleanTextWithGemini() async {
        // 1. Turn on the Gemini loading spinner
        await MainActor.run {
            withAnimation(.spring()) {
                isCleaningText = true
                fdaDetails = nil // Clear old FDA data just in case
                fdaSearchResults = []
                searchedMedicineName = ""
                manualFDASearchError = nil
                extractedDiagnosis = "" // Clear old diagnosis data
                manualSearchKeyword = "" // Clear old keyword
                pdfURL = nil // Clear old PDF
            }
        }
        
        do {
            // 2. Send the messy text to GeminiService
            let cleanData = try await GeminiService.shared.cleanPrescriptionText(rawText: extractedText)
            
            // 3. Update the UI with the beautiful, clean text!
            await MainActor.run {
                withAnimation(.spring()) {
                    extractedText = cleanData
                    isCleaningText = false
                }
            }
            
            // Extract Medicine and Fetch FDA Data
            await MainActor.run { isFetchingFDA = true }
            
            // Find medicine names and diagnosis from Gemini's output
            let lines = cleanData.components(separatedBy: .newlines)
            let medicineCandidates = extractMedicineCandidates(from: lines)
            
            // Look for our specific "Diagnosis" line
            if let diagnosisLine = lines.first(where: { $0.contains("Diagnosis:") }) {
                let cleanDiagnosis = diagnosisLine.replacingOccurrences(of: "🩺 Diagnosis:", with: "")
                                                  .replacingOccurrences(of: "Diagnosis:", with: "")
                                                  .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanDiagnosis.lowercased().contains("none") && !cleanDiagnosis.isEmpty {
                    // Extracting the first main condition word
                    let mainWord = cleanDiagnosis.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "health"
                    
                    await MainActor.run {
                        withAnimation(.spring()) {
                            self.extractedDiagnosis = mainWord
                            // Pre-fill the text box automatically!
                            self.manualSearchKeyword = mainWord
                        }
                    }
                }
            }
            
            // Fetch FDA data for all extracted medicine candidates
            let fetchedResults = await fetchFDADetailsForMedicines(medicineCandidates)

            let primaryResult = fetchedResults.first

            await MainActor.run {
                withAnimation(.spring()) {
                    self.fdaSearchResults = fetchedResults
                    self.fdaDetails = primaryResult?.details
                    self.searchedMedicineName = primaryResult?.medicineName.capitalized ?? ""
                    self.isFetchingFDA = false
                }
            }
            
        } catch {
            // If the internet drops or something fails, let the user know
            await MainActor.run {
                withAnimation(.spring()) {
                    // Check if it's a rate limit/quota error (429)
                    let errorText = error.localizedDescription
                    if errorText.contains("429") || errorText.contains("Resource Exhausted") || errorText.contains("error 1") {
                        extractedText = "Whoa, slow down! 🚦\n\nThe AI is processing too many requests at once. Please wait about 10 seconds and tap 'Clean with Gemini AI' again.\n\n---\nOriginal Text:\n\(extractedText)"
                    } else {
                        // Standard error fallback
                        extractedText = "Error communicating with AI: \(errorText)\n\nOriginal Text:\n\(extractedText)"
                    }
                    
                    isCleaningText = false
                    isFetchingFDA = false
                }
            }
        }
    }

    private func extractMedicineCandidates(from lines: [String]) -> [String] {
        var candidates: [String] = []

        func appendCandidates(from rawText: String) {
            let lineWithoutLeadingBullet = rawText
                .replacingOccurrences(of: "^[\\-•–]+\\s*", with: "", options: .regularExpression)

            let cleaned = lineWithoutLeadingBullet
                .replacingOccurrences(of: "💊", with: "")
                .replacingOccurrences(of: "Medications:", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: " and ", with: ",", options: .caseInsensitive)
                .replacingOccurrences(of: ";", with: ",")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !cleaned.isEmpty else { return }

            let parts = cleaned
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            candidates.append(contentsOf: parts)
        }

        if let medicationsIndex = lines.firstIndex(where: { $0.localizedCaseInsensitiveContains("Medications:") }) {
            // Parse the labeled medications line first.
            appendCandidates(from: lines[medicationsIndex])

            // Then parse following bullet/continuation lines until next major section heading.
            let stopKeywords = ["main drug:", "diagnosis:", "doctor:", "date:"]
            var index = medicationsIndex + 1
            while index < lines.count {
                let rawLine = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
                let lowerLine = rawLine.lowercased()

                if rawLine.isEmpty {
                    index += 1
                    continue
                }

                if stopKeywords.contains(where: { lowerLine.contains($0) }) {
                    break
                }

                // Include bullet style rows or wrapped continuation rows.
                let isMedicationLike = rawLine.hasPrefix("-") || rawLine.hasPrefix("•") || rawLine.hasPrefix("–") || !rawLine.contains(":")
                if isMedicationLike {
                    appendCandidates(from: rawLine)
                }

                index += 1
            }
        }

        if let mainDrugLine = lines.first(where: { $0.localizedCaseInsensitiveContains("Main Drug:") }) {
            let main = mainDrugLine
                .replacingOccurrences(of: "🔍 Main Drug:", with: "")
                .replacingOccurrences(of: "Main Drug:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !main.lowercased().contains("none") && !main.isEmpty {
                candidates.insert(main, at: 0)
            }
        }

        var seen = Set<String>()
        let deduped = candidates.filter {
            let cleaned = $0
                .replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let key = cleaned.lowercased()
            guard !key.isEmpty, !key.contains("none"), !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }

        return Array(deduped.prefix(6))
    }

    private func fetchFDADetailsForMedicines(_ names: [String]) async -> [FDASearchResult] {
        guard !names.isEmpty else { return [] }

        var results: [FDASearchResult] = []
        for name in names {
            if let details = try? await OpenFDAService.shared.fetchDrugDetails(for: name) {
                results.append(FDASearchResult(medicineName: name, details: details))
            }
        }
        return results
    }

    private func searchManualMedicineFDA() async {
        let query = manualMedicineSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        await MainActor.run {
            isManualFDASearching = true
            manualFDASearchError = nil
        }

        let details = try? await OpenFDAService.shared.fetchDrugDetails(for: query)

        await MainActor.run {
            if let details {
                let exists = fdaSearchResults.contains { $0.medicineName.lowercased() == query.lowercased() }
                if !exists {
                    fdaSearchResults.insert(FDASearchResult(medicineName: query, details: details), at: 0)
                }

                fdaDetails = fdaSearchResults.first?.details
                searchedMedicineName = fdaSearchResults.first?.medicineName ?? ""
                manualMedicineSearch = ""
            } else {
                manualFDASearchError = "No official FDA result found for '\(query)'."
            }

            isManualFDASearching = false
        }
    }
}
