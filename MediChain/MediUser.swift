//
//  MediUser.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import Foundation

// Phase 1 Mehedi: Logic to distinguish between Doctors and Patients
enum UserRole: String, Codable {
    case doctor = "Doctor"
    case patient = "Patient"
}

struct MediUser: Codable, Identifiable {
    var id: String { uid }
    let uid: String
    let email: String
    let role: UserRole // This drives the Dual-Portal Access
}
