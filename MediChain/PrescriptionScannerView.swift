//
//  PrescriptionScannerView.swift
//  MediChainUITests
//
//  Created by mehedi hasan on 7/3/26.
//

import SwiftUI

struct PrescriptionScannerView: View {
    @State private var isShowingScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var extractedText: String = ""
    @State private var isProcessing = false
    @State private var isPulsing = false // Drives the offline OCR loading animation
    
    // MUBIN'S ADDITION: Drives the Gemini AI loading animation
    @State private var isCleaningText = false
    
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
                        
                        // MARK: - Gemini AI Button (Replaces Old Save Button)
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
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingScanner) {
                ScannerView(scannedImages: $scannedImages)
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
        }
        
        textRecognizer.recognizeText(from: image) { result in
            withAnimation(.spring()) {
                self.extractedText = result
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Gemini AI Processing
    private func cleanTextWithGemini() async {
        // Turn on the loading spinner
        await MainActor.run {
            withAnimation(.spring()) {
                isCleaningText = true
            }
        }
        
        do {
            // Send the messy text to Mubin's GeminiService
            let cleanData = try await GeminiService.shared.cleanPrescriptionText(rawText: extractedText)
            
            // Update the UI with the beautiful, clean text!
            await MainActor.run {
                withAnimation(.spring()) {
                    extractedText = cleanData
                    isCleaningText = false
                }
            }
        } catch {
            // If the internet drops or something fails, let the user know
            await MainActor.run {
                withAnimation(.spring()) {
                    extractedText = "Error communicating with AI: \(error.localizedDescription)\n\nOriginal Text:\n\(extractedText)"
                    isCleaningText = false
                }
            }
        }
    }
}
