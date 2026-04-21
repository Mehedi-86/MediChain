// MedicalRecordModels.swift
// MediChain

import Foundation
import FirebaseFirestore

struct PatientPrescription: Codable, Identifiable {
    @DocumentID var id: String?
    let patientId: String
    var title: String
    var content: String
    var addedBy: String         // "patient" or "doctor"
    var doctorName: String?
    var appointmentId: String?
    let createdAt: Date

    var isFromDoctor: Bool { addedBy == "doctor" }
}

struct BloodTestRecord: Codable, Identifiable {
    @DocumentID var id: String?
    let patientId: String
    var testName: String
    var content: String
    let createdAt: Date
}
