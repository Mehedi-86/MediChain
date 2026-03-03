//
//  Appointment.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import Foundation

struct Appointment: Codable, Identifiable {
    var id: String? // Firestore Document ID
    let patientId: String
    let doctorId: String
    let date: Date
    let status: String // e.g., "Scheduled", "Completed", "Cancelled"
    let notes: String
}
