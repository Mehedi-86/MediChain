//
//  AuthViewModel.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: MediUser?
    @Published var isSignedIn = false
    @Published var appointments: [Appointment] = [] // Dynamic queue for doctors
    
    private var db = Firestore.firestore()
    
    // Function for New Users
    func signUp(email: String, password: String, role: UserRole) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Auth Error: \(error.localizedDescription)")
                return
            }
            
            guard let uid = result?.user.uid else { return }
            let newUser = MediUser(uid: uid, email: email, role: role)
            
            try? self.db.collection("users").document(uid).setData(from: newUser) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.currentUser = newUser
                        self.isSignedIn = true
                    }
                }
            }
        }
    }
    
    // Function for Existing Users
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Login Error: \(error.localizedDescription)")
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            self.db.collection("users").document(uid).getDocument { snapshot, error in
                if let data = snapshot?.data(), let roleString = data["role"] as? String {
                    DispatchQueue.main.async {
                        self.currentUser = MediUser(
                            uid: uid,
                            email: email,
                            role: UserRole(rawValue: roleString) ?? .patient
                        )
                        self.isSignedIn = true
                    }
                }
            }
        }
    }
    
    // Step 1: Update AuthViewModel to Sync Appointments
    func fetchDoctorAppointments() {
        guard let doctorId = currentUser?.uid else { return }
        
        // Listen for appointments specifically for this doctor
        db.collection("appointments")
            .whereField("doctorId", isEqualTo: doctorId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Fetch Error: \(error.localizedDescription)")
                    return
                }
                
                // Map the Firestore data to your local array using the internal Firebase tools
                self.appointments = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Appointment.self)
                } ?? []
            }
    }

    func scheduleAppointment(doctorId: String, date: Date, notes: String) {
        guard let patientId = currentUser?.uid else { return }
        let newAppt = Appointment(patientId: patientId, doctorId: doctorId, date: date, status: "Scheduled", notes: notes)
        try? db.collection("appointments").addDocument(from: newAppt)
    }
    
    // Add these properties and functions to your AuthViewModel class in AuthViewModel.swift

    @Published var allDoctors: [MediUser] = []

    // Fetches all users with the 'Doctor' role from the cloud
    func fetchAllDoctors() {
        db.collection("users")
            .whereField("role", isEqualTo: UserRole.doctor.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching doctors: \(error.localizedDescription)")
                    return
                }
                
                self.allDoctors = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: MediUser.self)
                } ?? []
            }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        DispatchQueue.main.async {
            self.isSignedIn = false
            self.currentUser = nil
            self.appointments = []
        }
    }
}
