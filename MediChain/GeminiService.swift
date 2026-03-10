//
//  GeminiService.swift
//  MediChain
//
//  Created by mehedi hasan on 8/3/26.
//

import Foundation
import GoogleGenerativeAI

class GeminiService {
    // A shared instance so we can easily call it from anywhere
    static let shared = GeminiService()
    
    // Securely pull the API key from the Info.plist
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !key.isEmpty else {
            fatalError("🚨 Gemini API Key is missing! Check your Config.xcconfig and Info.plist.")
        }
        return key
    }
    
    // Initialize the Gemini 1.5 Flash model
    // Added "-latest" to ensure the SDK finds the active version
    private lazy var model = GenerativeModel(name: "gemini-flash-latest", apiKey: apiKey)
    
    // The main function that Mubin is building
    func cleanPrescriptionText(rawText: String) async throws -> String {
        let prompt = """
        You are an expert medical AI assistant. I am going to give you raw, messy text extracted from a handwritten doctor's prescription using an offline OCR scanner. It contains typos, bad formatting, and misspelled medical terms (for example, reading 'Not Cancer' as 'Natcanee~').
        
        Please analyze the text, figure out what the doctor actually meant, fix the spelling mistakes, and return a clean, readable summary formatted exactly like this:
        
        👨‍⚕️ Doctor: [Name]
        📅 Date: [Date]
        🩺 Diagnosis: [Symptoms/Concern]
        💊 Medications: [List of meds]
        🔍 Main Drug: [Single primary drug name without dosage (e.g., Gabapentin). If no meds, write NONE]
        
        Do not include any conversational text, just return the clean medical record.
        
        Raw OCR Text:
        \(rawText)
        """
        
        // Send the prompt to Google's servers
        let response = try await model.generateContent(prompt)
        
        // Return the cleaned-up string
        return response.text ?? "Error: Could not generate a response from Gemini."
    }
}
