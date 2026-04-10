//
//  MediUser.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import Foundation

enum UserRole: String, Codable {
    case doctor = "Doctor"
    case patient = "Patient"
}

struct MediUser: Codable, Identifiable, Hashable {
    var id: String { uid }
    let uid: String
    let email: String
    var fullName: String? // --- NEW FIELD ---
    let role: UserRole
    
    var dutyStart: String?
    var dutyEnd: String?
    var dailyLimit: Int?
    var specialty: String?
    var region: String?
    var bloodGroup: String?
    var age: String?
    var weight: String?
}
