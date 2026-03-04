//
//  AppointmentModels.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

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
    let doctorId: String
    var doctorName: String?
    var timeSlot: String? // --- NEW FIELD to hold "7:00 PM - 9:00 PM" ---
    let date: Date
    let status: String
    let notes: String
}
