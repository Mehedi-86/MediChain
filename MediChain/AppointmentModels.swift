// AppointmentModels.swift
// MediChain

import Foundation
import FirebaseFirestore

struct DoctorAvailability: Codable {
    let doctorId: String
    let date: String
    var currentPatientCount: Int
    let maxLimit: Int
}

struct Appointment: Codable, Identifiable {
    @DocumentID var id: String?
    let patientId: String
    var patientName: String?
    let doctorId: String
    var doctorName: String?
    var timeSlot: String?
    let date: Date
    let status: String
    let notes: String
    var serialNumber: Int?
    var prescriptionId: String?   // NEW: links to a doctor-written PatientPrescription
}
