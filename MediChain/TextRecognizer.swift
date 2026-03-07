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
            
            let extractedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                completion(extractedText)
            }
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("❌ Failed to recognize text: \(error.localizedDescription)")
            completion("Error: Failed to process text.")
        }
    }
}
