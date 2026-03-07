//
//  TextRecognizer.swift
//  MediChainUITests
//
//  Created by mehedi hasan on 7/3/26.
//

import Vision
import UIKit

class TextRecognizer {
    
    func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("Error: Could not process image.")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion("No text found.")
                return
            }
            
            // 1. Extract raw text
            let rawText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            // 2. Format and clean up the text
            let formattedText = self.cleanUpText(rawText)
            
            DispatchQueue.main.async {
                completion(formattedText)
            }
        }
        
        // Use the most accurate recognition level and language correction
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("❌ Failed to recognize text: \(error.localizedDescription)")
            completion("Error: Failed to process text.")
        }
    }
    
    // MARK: - Text Formatting Helper
    private func cleanUpText(_ rawText: String) -> String {
        let lines = rawText.components(separatedBy: .newlines)
        var cleanedLines: [String] = []
        
        for line in lines {
            // Remove random extra spaces at the start/end of lines
            var cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip totally empty lines
            if cleanLine.isEmpty { continue }
            
            // Convert standard prescription arrows/dashes into clean Bullet Points
            if cleanLine.hasPrefix("->") || cleanLine.hasPrefix("-") || cleanLine.hasPrefix("+") || cleanLine.hasPrefix("*") {
                // Remove the old symbol and replace it with a clean bullet
                let textWithoutSymbol = cleanLine.dropFirst(2).trimmingCharacters(in: .whitespaces)
                cleanLine = "• \(textWithoutSymbol)"
            }
            
            cleanedLines.append(cleanLine)
        }
        
        // Join the lines back together with double-spacing for easier reading
        return cleanedLines.joined(separator: "\n\n")
    }
}
