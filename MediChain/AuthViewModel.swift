//
//  AuthViewModel.swift
//  MediChain
//
//  Created by mehedi hasan on 3/4/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: MediUser?
    @Published var isSignedIn = false
    @Published var appointments: [Appointment] = []
    @Published var availableDoctors: [MediUser] = []
    @Published var patientAppointments: [Appointment] = []
    
    private var db = Firestore.firestore()
    
    // MARK: - Authentication
    
    // UPDATED: Now requires fullName during sign up
    func signUp(email: String, password: String, fullName: String, role: UserRole) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Auth Error: \(error.localizedDescription)")
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            // Save fullName to the database
            let newUser = MediUser(uid: uid, email: email, fullName: fullName, role: role, dutyStart: "18:00", dutyEnd: "20:00", dailyLimit: 5)
            
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
                        self.currentUser = try? snapshot?.data(as: MediUser.self)
                        self.isSignedIn = true
                    }
                }
            }
        }
    }
    
    // MARK: - Doctor Duty Management
    
    func updateDoctorDuty(limit: Int, start: String, end: String) {
        guard let uid = currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "dailyLimit": limit,
            "dutyStart": start,
            "dutyEnd": end
        ]) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.currentUser?.dailyLimit = limit
                    self.currentUser?.dutyStart = start
                    self.currentUser?.dutyEnd = end
                }
            }
        }
    }
    
    // MARK: - Appointment Logic (Fetching)
    
    func fetchDoctorAppointments() {
        guard let doctorId = currentUser?.uid else { return }
        
        db.collection("appointments")
            .whereField("doctorId", isEqualTo: doctorId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Fetch Error: \(error.localizedDescription)")
                    return
                }
                
                self.appointments = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Appointment.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self.appointments.sort { $0.date < $1.date }
                }
            }
    }

    func fetchAvailableDoctors(for date: Date) {
        let dateString = formatDate(date)
        
        db.collection("users").whereField("role", isEqualTo: UserRole.doctor.rawValue).getDocuments { snapshot, _ in
            let allDocs = snapshot?.documents.compactMap { try? $0.data(as: MediUser.self) } ?? []
            
            DispatchQueue.main.async { self.availableDoctors = [] }
            
            for doctor in allDocs {
                let availabilityRef = self.db.collection("availability").document("\(doctor.uid)_\(dateString)")
                
                availabilityRef.getDocument { snap, _ in
                    let count = snap?.data()?["currentPatientCount"] as? Int ?? 0
                    let limit = doctor.dailyLimit ?? 5
                    
                    if count < limit {
                        DispatchQueue.main.async {
                            if !self.availableDoctors.contains(where: { $0.uid == doctor.uid }) {
                                self.availableDoctors.append(doctor)
                            }
                        }
                    }
                }
            }
        }
    }

    func fetchPatientAppointments() {
        guard let uid = currentUser?.uid else { return }
        
        db.collection("appointments")
            .whereField("patientId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching: \(error.localizedDescription)")
                    return
                }
                
                let allAppts = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Appointment.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self.patientAppointments = allAppts.filter { appt in
                        if appt.date < Calendar.current.startOfDay(for: Date()) {
                            self.deleteExpiredAppointment(id: appt.id)
                            return false
                        }
                        return true
                    }
                    self.patientAppointments.sort { $0.date < $1.date }
                }
            }
    }

    // MARK: - Appointment Logic (Booking & Canceling)
        
        func scheduleAppointment(doctorId: String, doctorName: String, timeSlot: String, date: Date, notes: String) {
            guard let patientId = currentUser?.uid else { return }
            let dateString = formatDate(date)
            let availabilityRef = db.collection("availability").document("\(doctorId)_\(dateString)")
            
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let availDoc: DocumentSnapshot
                do { try availDoc = transaction.getDocument(availabilityRef) }
                catch { return nil }
                
                let currentCount = availDoc.data()?["currentPatientCount"] as? Int ?? 0
                
                transaction.setData([
                    "doctorId": doctorId,
                    "date": dateString,
                    "currentPatientCount": currentCount + 1
                ], forDocument: availabilityRef, merge: true)
                
                return nil
            }) { (object, error) in
                if let error = error {
                    print("❌ Transaction failed: \(error.localizedDescription)")
                } else {
                    // THE FIX: Smart fallback for old accounts that don't have a fullName saved
                    let emailPrefix = self.currentUser?.email.components(separatedBy: "@").first?.capitalized ?? "Patient"
                    let finalPatientName = self.currentUser?.fullName ?? emailPrefix
                    
                    let newAppt = Appointment(patientId: patientId, patientName: finalPatientName, doctorId: doctorId, doctorName: doctorName, timeSlot: timeSlot, date: date, status: "Scheduled", notes: notes)
                    try? self.db.collection("appointments").addDocument(from: newAppt)
                }
            }
        }
    
    func cancelAppointment(appointment: Appointment) {
        guard let docId = appointment.id else { return }
        
        db.collection("appointments").document(docId).delete { error in
            if error == nil {
                print("🗑️ Appointment canceled by patient.")
                let dateString = self.formatDate(appointment.date)
                let availabilityRef = self.db.collection("availability").document("\(appointment.doctorId)_\(dateString)")
                
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    let availDoc: DocumentSnapshot
                    do { try availDoc = transaction.getDocument(availabilityRef) }
                    catch { return nil }
                    
                    let currentCount = availDoc.data()?["currentPatientCount"] as? Int ?? 0
                    if currentCount > 0 {
                        transaction.updateData(["currentPatientCount": currentCount - 1], forDocument: availabilityRef)
                    }
                    return nil
                }) { _, _ in print("✅ Doctor capacity restored.") }
            }
        }
    }

    private func deleteExpiredAppointment(id: String?) {
        guard let docId = id else { return }
        db.collection("appointments").document(docId).delete() { _ in }
    }
    
    // MARK: - Helpers
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        DispatchQueue.main.async {
            self.isSignedIn = false
            self.currentUser = nil
            self.appointments = []
            self.availableDoctors = []
            self.patientAppointments = []
        }
    }
}
