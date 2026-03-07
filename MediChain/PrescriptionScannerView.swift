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
    @State private var extractedText: String = "No document scanned yet."
    @State private var isProcessing = false
    
    // Instantiate the AI engine you just built
    let textRecognizer = TextRecognizer()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - Header
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.teal)
                                .padding(.bottom, 5)
                            
                            Text("Digitize Prescriptions")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Scan physical documents to instantly extract the doctor's name, date, and notes using Apple Vision AI.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 30)
                        
                        // MARK: - Scan Button
                        Button(action: {
                            isShowingScanner = true
                        }) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.title3)
                                Text("Open Camera Scanner")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .teal.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        
                        // MARK: - AI Results Area
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Extracted Data")
                                    .font(.headline)
                                Spacer()
                                if isProcessing {
                                    ProgressView()
                                }
                            }
                            
                            Divider()
                            
                            // Displays the live text returned from TextRecognizer
                            Text(extractedText)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(extractedText == "No document scanned yet." ? .gray : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                        
                        // MARK: - Save Button (Appears after scanning)
                        if !scannedImages.isEmpty && !isProcessing {
                            Button(action: {
                                // TODO: We will add the SwiftData database save logic here!
                                print("Ready to save to database!")
                            }) {
                                Text("Save to Digital Records")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            // Opens the ScannerView when the button is tapped
            .sheet(isPresented: $isShowingScanner) {
                ScannerView(scannedImages: $scannedImages)
            }
            // Automatically triggers the AI as soon as the camera closes
            .onChange(of: scannedImages) { newImages in
                guard let firstImage = newImages.first else { return }
                processImage(firstImage)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - AI Processing Function
    private func processImage(_ image: UIImage) {
        isProcessing = true
        extractedText = "Analyzing document..."
        
        // Calls the TextRecognizer file you made earlier
        textRecognizer.recognizeText(from: image) { result in
            self.extractedText = result
            self.isProcessing = false
        }
    }
}
