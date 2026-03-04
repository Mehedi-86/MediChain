//
//  MediUser.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import Foundation

// Logic to distinguish between Doctors and Patients
enum UserRole: String, Codable {
    case doctor = "Doctor"
    case patient = "Patient"
}

struct MediUser: Codable, Identifiable, Hashable { // Added Hashable for Picker support
    var id: String { uid }
    let uid: String
    let email: String
    let role: UserRole
    
    // New Fields for Doctor Capacity
    var dutyStart: String?
    var dutyEnd: String?
    var dailyLimit: Int?
}
