//
//  AuthViewModel.swift
//  MediChain
//
//  Created by mehedi hasan on 3/4/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage // NEW: Required to save the actual image file to the cloud
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: MediUser?
    @Published var isSignedIn = false
    @Published var appointments: [Appointment] = []
    @Published var availableDoctors: [MediUser] = []
    @Published var patientAppointments: [Appointment] = []
    
    private var db = Firestore.firestore()
    
    // MARK: - Authentication
    
    // UPDATED: Now requires fullName AND region during sign up
    func signUp(email: String, password: String, fullName: String, role: UserRole, region: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Auth Error: \(error.localizedDescription)")
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            // Save fullName and region to the database
            // NOTE: If the user is a patient, region will just be an empty string ""
            let newUser = MediUser(uid: uid, email: email, fullName: fullName, role: role, dutyStart: "18:00", dutyEnd: "20:00", dailyLimit: 5, region: region)
            
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
    
    // MARK: - Update Patient Info
    // UPDATED: Now includes fullName
    func updatePatientInfo(fullName: String, bloodGroup: String, age: String, weight: String) {
        guard let uid = currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "fullName": fullName,
            "bloodGroup": bloodGroup,
            "age": age,
            "weight": weight
        ]) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.currentUser?.fullName = fullName // Update the local state!
                    self.currentUser?.bloodGroup = bloodGroup
                    self.currentUser?.age = age
                    self.currentUser?.weight = weight
                }
            } else {
                print("❌ Error updating info: \(error!.localizedDescription)")
            }
        }
    }
    
    // MARK: - Profile Picture Upload
    func uploadProfilePicture(imageData: Data) {
        guard let uid = currentUser?.uid else { return }
        
        // 1. The Secret: Name the file the exact same thing every time (their UID)
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("profile_pictures/\(uid).jpg")
        
        // 2. Upload the new data (this instantly overwrites any old photo!)
        fileRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ Upload error: \(error.localizedDescription)")
                return
            }
            
            // 3. Grab the secure download link
            fileRef.downloadURL { url, error in
                guard let downloadURL = url?.absoluteString else { return }
                
                // 4. Save that link to the user's Firestore document
                self.db.collection("users").document(uid).updateData([
                    "profileImageUrl": downloadURL
                ]) { error in
                    if error == nil {
                        print("✅ Profile picture secured in the cloud!")
                        DispatchQueue.main.async {
                            self.currentUser?.profileImageUrl = downloadURL
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Doctor Duty Management
        
    // UPDATED: Now saves the doctor's specialty
    func updateDoctorDuty(limit: Int, start: String, end: String, specialty: String) {
        guard let uid = currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "dailyLimit": limit,
            "dutyStart": start,
            "dutyEnd": end,
            "specialty": specialty // Save to Firebase!
        ]) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.currentUser?.dailyLimit = limit
                    self.currentUser?.dutyStart = start
                    self.currentUser?.dutyEnd = end
                    self.currentUser?.specialty = specialty // Update local state
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
                    // THE FIX: Two-step sorting logic
                    self.appointments.sort { appt1, appt2 in
                        // 1. Strip away the exact hours/minutes to compare just the calendar day
                        let day1 = Calendar.current.startOfDay(for: appt1.date)
                        let day2 = Calendar.current.startOfDay(for: appt2.date)
                        
                        if day1 == day2 {
                            // 2. If it's the same day, sort by Serial Number
                            return (appt1.serialNumber ?? 0) < (appt2.serialNumber ?? 0)
                        }
                        
                        // Otherwise, sort by the date
                        return day1 < day2
                    }
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
                    
                    // THE FIX: Two-step sorting logic applied to the Patient Dashboard!
                    self.patientAppointments.sort { appt1, appt2 in
                        // 1. Strip away the exact hours/minutes to compare just the calendar day
                        let day1 = Calendar.current.startOfDay(for: appt1.date)
                        let day2 = Calendar.current.startOfDay(for: appt2.date)
                        
                        if day1 == day2 {
                            // 2. If it's the same day, sort by Serial Number
                            return (appt1.serialNumber ?? 0) < (appt2.serialNumber ?? 0)
                        }
                        
                        // Otherwise, sort by the date
                        return day1 < day2
                    }
                }
            }
    }

    // MARK: - Appointment Logic (Booking & Canceling)
        
    // UPDATED: Now includes a completion handler and duplicate checking
    func scheduleAppointment(doctorId: String, doctorName: String, timeSlot: String, date: Date, notes: String, completion: @escaping (Bool, String) -> Void) {
        guard let patientId = currentUser?.uid else { return }
        let dateString = formatDate(date)
        
        // 1. PREVENT MULTIPLE APPOINTMENTS ON THE SAME DAY
        let alreadyBooked = patientAppointments.contains { formatDate($0.date) == dateString }
        if alreadyBooked {
            completion(false, "You already have an appointment scheduled for \(dateString). Please choose another date.")
            return
        }
        
        let availabilityRef = db.collection("availability").document("\(doctorId)_\(dateString)")
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let availDoc: DocumentSnapshot
            do { try availDoc = transaction.getDocument(availabilityRef) }
            catch { return nil }
            
            let currentCount = availDoc.data()?["currentPatientCount"] as? Int ?? 0
            let newSerial = currentCount + 1 // This is their exact queue position
            
            transaction.setData([
                "doctorId": doctorId,
                "date": dateString,
                "currentPatientCount": newSerial
            ], forDocument: availabilityRef, merge: true)
            
            return newSerial // Pass the serial number out of the transaction
        }) { (object, error) in
            if let error = error {
                completion(false, "Booking failed: \(error.localizedDescription)")
            } else if let serialNumber = object as? Int {
                let emailPrefix = self.currentUser?.email.components(separatedBy: "@").first?.capitalized ?? "Patient"
                let finalPatientName = self.currentUser?.fullName ?? emailPrefix
                
                // Save the serial number into the new appointment
                let newAppt = Appointment(patientId: patientId, patientName: finalPatientName, doctorId: doctorId, doctorName: doctorName, timeSlot: timeSlot, date: date, status: "Scheduled", notes: notes, serialNumber: serialNumber)
                
                try? self.db.collection("appointments").addDocument(from: newAppt)
                completion(true, "Success")
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
