// AuthViewModel.swift
// MediChain

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: MediUser?
    @Published var isSignedIn = false
    @Published var isAdminSession = false
    @Published var appointments: [Appointment] = []
    @Published var availableDoctors: [MediUser] = []
    @Published var patientAppointments: [Appointment] = []
    @Published var adminDoctors: [MediUser] = []
    @Published var adminPatients: [MediUser] = []
    @Published var adminAppointments: [Appointment] = []
    @Published var breakingNews: [BreakingNewsItem] = []

    // MARK: - Medical Records (NEW)
    @Published var patientPrescriptions: [PatientPrescription] = []
    @Published var patientBloodTests: [BloodTestRecord] = []

    private let adminEmail = "admin@gmail.com"
    private let adminPassword = "123456"
    private var db = Firestore.firestore()

    // MARK: - Authentication

    func signUp(email: String, password: String, fullName: String, role: UserRole, region: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Auth Error: \(error.localizedDescription)")
                return
            }
            guard let uid = result?.user.uid else { return }

            let newUser = MediUser(uid: uid, email: email, fullName: fullName, role: role,
                                  dutyStart: "18:00", dutyEnd: "20:00", dailyLimit: 5, region: region)

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
        if email.lowercased() == adminEmail && password == adminPassword {
            let adminUser = MediUser(uid: "admin-local-account", email: adminEmail,
                                    fullName: "System Admin", role: .admin)
            DispatchQueue.main.async {
                self.currentUser = adminUser
                self.isAdminSession = true
                self.isSignedIn = true
            }
            return
        }

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
                        self.isAdminSession = roleString == UserRole.admin.rawValue
                        self.isSignedIn = true
                    }
                }
            }
        }
    }

    // MARK: - Update Patient Info

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
                    self.currentUser?.fullName = fullName
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

        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("profile_pictures/\(uid).jpg")

        fileRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ Upload error: \(error.localizedDescription)")
                return
            }
            fileRef.downloadURL { url, error in
                guard let downloadURL = url?.absoluteString else { return }
                self.db.collection("users").document(uid).updateData([
                    "profileImageUrl": downloadURL
                ]) { error in
                    if error == nil {
                        DispatchQueue.main.async {
                            self.currentUser?.profileImageUrl = downloadURL
                        }
                    }
                }
            }
        }
    }

    // MARK: - Doctor Duty Management

    func updateDoctorDuty(limit: Int, start: String, end: String, specialty: String) {
        guard let uid = currentUser?.uid else { return }

        db.collection("users").document(uid).updateData([
            "dailyLimit": limit,
            "dutyStart": start,
            "dutyEnd": end,
            "specialty": specialty
        ]) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.currentUser?.dailyLimit = limit
                    self.currentUser?.dutyStart = start
                    self.currentUser?.dutyEnd = end
                    self.currentUser?.specialty = specialty
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
                    self.appointments.sort { appt1, appt2 in
                        let day1 = Calendar.current.startOfDay(for: appt1.date)
                        let day2 = Calendar.current.startOfDay(for: appt2.date)
                        if day1 == day2 {
                            return (appt1.serialNumber ?? 0) < (appt2.serialNumber ?? 0)
                        }
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

                    self.patientAppointments.sort { appt1, appt2 in
                        let day1 = Calendar.current.startOfDay(for: appt1.date)
                        let day2 = Calendar.current.startOfDay(for: appt2.date)
                        if day1 == day2 {
                            return (appt1.serialNumber ?? 0) < (appt2.serialNumber ?? 0)
                        }
                        return day1 < day2
                    }
                }
            }
    }

    // MARK: - Appointment Logic (Booking & Canceling)

    func scheduleAppointment(doctorId: String, doctorName: String, timeSlot: String, date: Date, notes: String, completion: @escaping (Bool, String) -> Void) {
        guard let patientId = currentUser?.uid else { return }
        let dateString = formatDate(date)

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
            let newSerial = currentCount + 1

            transaction.setData([
                "doctorId": doctorId,
                "date": dateString,
                "currentPatientCount": newSerial
            ], forDocument: availabilityRef, merge: true)

            return newSerial
        }) { (object, error) in
            if let error = error {
                completion(false, "Booking failed: \(error.localizedDescription)")
            } else if let serialNumber = object as? Int {
                let emailPrefix = self.currentUser?.email.components(separatedBy: "@").first?.capitalized ?? "Patient"
                let finalPatientName = self.currentUser?.fullName ?? emailPrefix

                let newAppt = Appointment(patientId: patientId, patientName: finalPatientName,
                                         doctorId: doctorId, doctorName: doctorName,
                                         timeSlot: timeSlot, date: date, status: "Scheduled",
                                         notes: notes, serialNumber: serialNumber)

                try? self.db.collection("appointments").addDocument(from: newAppt)
                completion(true, "Success")
            }
        }
    }

    func cancelAppointment(appointment: Appointment) {
        guard let docId = appointment.id else { return }

        db.collection("appointments").document(docId).delete { error in
            if error == nil {
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
                }) { _, _ in }
            }
        }
    }

    private func deleteExpiredAppointment(id: String?) {
        guard let docId = id else { return }
        db.collection("appointments").document(docId).delete() { _ in }
    }

    // MARK: - Fetch Specific User Data

    func fetchUserDetails(uid: String, completion: @escaping (MediUser?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, _ in
            let user = try? snapshot?.data(as: MediUser.self)
            DispatchQueue.main.async { completion(user) }
        }
    }

    // MARK: - Patient Prescriptions (NEW)

    func fetchPatientPrescriptions() {
        guard let uid = currentUser?.uid else { return }

        db.collection("prescriptions")
            .whereField("patientId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Fetch prescriptions error: \(error.localizedDescription)")
                    return
                }
                let items = (snapshot?.documents.compactMap { try? $0.data(as: PatientPrescription.self) } ?? [])
                    .sorted { $0.createdAt > $1.createdAt }
                DispatchQueue.main.async { self.patientPrescriptions = items }
            }
    }

    func addPatientPrescription(title: String, content: String, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUser?.uid else { completion?(false); return }

        let prescription = PatientPrescription(
            patientId: uid,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            addedBy: "patient",
            doctorName: nil,
            appointmentId: nil,
            createdAt: Date()
        )

        do {
            _ = try db.collection("prescriptions").addDocument(from: prescription)
            completion?(true)
        } catch {
            print("❌ Add prescription error: \(error.localizedDescription)")
            completion?(false)
        }
    }

    func deletePatientPrescription(_ prescription: PatientPrescription, completion: ((Bool) -> Void)? = nil) {
        guard let id = prescription.id else { completion?(false); return }
        db.collection("prescriptions").document(id).delete { error in
            completion?(error == nil)
        }
    }

    // MARK: - Blood Tests (NEW)

    func fetchPatientBloodTests() {
        guard let uid = currentUser?.uid else { return }

        db.collection("bloodTests")
            .whereField("patientId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Fetch blood tests error: \(error.localizedDescription)")
                    return
                }
                let items = (snapshot?.documents.compactMap { try? $0.data(as: BloodTestRecord.self) } ?? [])
                    .sorted { $0.createdAt > $1.createdAt }
                DispatchQueue.main.async { self.patientBloodTests = items }
            }
    }

    func addBloodTest(testName: String, content: String, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUser?.uid else { completion?(false); return }

        let record = BloodTestRecord(
            patientId: uid,
            testName: testName.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )

        do {
            _ = try db.collection("bloodTests").addDocument(from: record)
            completion?(true)
        } catch {
            print("❌ Add blood test error: \(error.localizedDescription)")
            completion?(false)
        }
    }

    func deleteBloodTest(_ bloodTest: BloodTestRecord, completion: ((Bool) -> Void)? = nil) {
        guard let id = bloodTest.id else { completion?(false); return }
        db.collection("bloodTests").document(id).delete { error in
            completion?(error == nil)
        }
    }

    // MARK: - Doctor Writes Prescription (NEW)

    /// Called by a doctor to write a prescription for a patient after/during an appointment.
    func addDoctorPrescription(
        patientId: String,
        appointmentId: String?,
        title: String,
        content: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        let rawName = currentUser?.fullName
            ?? currentUser?.email.components(separatedBy: "@").first?.capitalized
            ?? "Doctor"
        let doctorDisplayName = rawName.hasPrefix("Dr.") ? rawName : "Dr. \(rawName)"

        let prescription = PatientPrescription(
            patientId: patientId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            addedBy: "doctor",
            doctorName: doctorDisplayName,
            appointmentId: appointmentId,
            createdAt: Date()
        )

        do {
            let ref = try db.collection("prescriptions").addDocument(from: prescription)

            // Link the prescription back to the appointment so the patient can find it
            if let appointmentId = appointmentId {
                db.collection("appointments").document(appointmentId).updateData([
                    "prescriptionId": ref.documentID
                ])
            }
            completion?(true)
        } catch {
            print("❌ Add doctor prescription error: \(error.localizedDescription)")
            completion?(false)
        }
    }

    // MARK: - Fetch Records for a Specific Patient (Doctor view) (NEW)

    func fetchPrescriptionsForPatient(patientId: String, completion: @escaping ([PatientPrescription]) -> Void) {
        db.collection("prescriptions")
            .whereField("patientId", isEqualTo: patientId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Fetch patient prescriptions error: \(error.localizedDescription)")
                    completion([])
                    return
                }
                let items = (snapshot?.documents.compactMap { try? $0.data(as: PatientPrescription.self) } ?? [])
                    .sorted { $0.createdAt > $1.createdAt }
                DispatchQueue.main.async { completion(items) }
            }
    }

    func fetchBloodTestsForPatient(patientId: String, completion: @escaping ([BloodTestRecord]) -> Void) {
        db.collection("bloodTests")
            .whereField("patientId", isEqualTo: patientId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Fetch patient blood tests error: \(error.localizedDescription)")
                    completion([])
                    return
                }
                let items = (snapshot?.documents.compactMap { try? $0.data(as: BloodTestRecord.self) } ?? [])
                    .sorted { $0.createdAt > $1.createdAt }
                DispatchQueue.main.async { completion(items) }
            }
    }

    /// Fetch a single prescription by its document ID (used by patient to load linked prescription)
    func fetchPrescriptionById(_ id: String, completion: @escaping (PatientPrescription?) -> Void) {
        db.collection("prescriptions").document(id).getDocument { snapshot, _ in
            let prescription = try? snapshot?.data(as: PatientPrescription.self)
            DispatchQueue.main.async { completion(prescription) }
        }
    }

    // MARK: - Admin Data

    func fetchAdminDoctors() {
        db.collection("users")
            .whereField("role", isEqualTo: UserRole.doctor.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Admin doctor fetch error: \(error.localizedDescription)")
                    return
                }
                let doctors = snapshot?.documents.compactMap { try? $0.data(as: MediUser.self) } ?? []
                DispatchQueue.main.async {
                    self.adminDoctors = doctors.sorted {
                        ($0.fullName ?? $0.email).localizedCaseInsensitiveCompare($1.fullName ?? $1.email) == .orderedAscending
                    }
                }
            }
    }

    func fetchAdminPatients() {
        db.collection("users")
            .whereField("role", isEqualTo: UserRole.patient.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Admin patient fetch error: \(error.localizedDescription)")
                    return
                }
                let patients = snapshot?.documents.compactMap { try? $0.data(as: MediUser.self) } ?? []
                DispatchQueue.main.async {
                    self.adminPatients = patients.sorted {
                        ($0.fullName ?? $0.email).localizedCaseInsensitiveCompare($1.fullName ?? $1.email) == .orderedAscending
                    }
                }
            }
    }

    func fetchAdminAppointments() {
        db.collection("appointments")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Admin appointment fetch error: \(error.localizedDescription)")
                    return
                }
                let appts = snapshot?.documents.compactMap { try? $0.data(as: Appointment.self) } ?? []
                DispatchQueue.main.async {
                    self.adminAppointments = appts.sorted { $0.date > $1.date }
                }
            }
    }

    func fetchBreakingNews() {
        db.collection("breakingNews")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Breaking news fetch error: \(error.localizedDescription)")
                    return
                }
                let items = snapshot?.documents.compactMap { try? $0.data(as: BreakingNewsItem.self) } ?? []
                DispatchQueue.main.async { self.breakingNews = items }
            }
    }

    func addBreakingNews(title: String, brief: String, article: String, completion: ((Bool) -> Void)? = nil) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBrief = brief.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArticle = article.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty, !cleanBrief.isEmpty, !cleanArticle.isEmpty else {
            completion?(false)
            return
        }

        let item = BreakingNewsItem(title: cleanTitle, brief: cleanBrief, article: cleanArticle,
                                   message: nil, createdAt: Date())
        do {
            _ = try db.collection("breakingNews").addDocument(from: item)
            completion?(true)
        } catch {
            print("❌ Add breaking news error: \(error.localizedDescription)")
            completion?(false)
        }
    }

    func deleteBreakingNews(item: BreakingNewsItem, completion: ((Bool) -> Void)? = nil) {
        guard let id = item.id else { completion?(false); return }
        db.collection("breakingNews").document(id).delete { error in
            if let error = error {
                print("❌ Delete breaking news error: \(error.localizedDescription)")
                completion?(false)
            } else {
                completion?(true)
            }
        }
    }

    func deleteUserRegistration(user: MediUser, completion: ((Bool) -> Void)? = nil) {
        guard user.role != .admin else { completion?(false); return }

        let group = DispatchGroup()
        var hadError = false
        let lock = NSLock()

        group.enter()
        db.collection("users").document(user.uid).delete { error in
            if let error = error {
                print("❌ User doc delete error: \(error.localizedDescription)")
                lock.lock(); hadError = true; lock.unlock()
            }
            group.leave()
        }

        if user.role == .doctor {
            group.enter()
            deleteDocuments(in: db.collection("appointments").whereField("doctorId", isEqualTo: user.uid)) { success in
                if !success { lock.lock(); hadError = true; lock.unlock() }
                group.leave()
            }
            group.enter()
            deleteDocuments(in: db.collection("availability").whereField("doctorId", isEqualTo: user.uid)) { success in
                if !success { lock.lock(); hadError = true; lock.unlock() }
                group.leave()
            }
        }

        if user.role == .patient {
            group.enter()
            deleteDocuments(in: db.collection("appointments").whereField("patientId", isEqualTo: user.uid)) { success in
                if !success { lock.lock(); hadError = true; lock.unlock() }
                group.leave()
            }
            group.enter()
            deleteDocuments(in: db.collection("prescriptions").whereField("patientId", isEqualTo: user.uid)) { success in
                if !success { lock.lock(); hadError = true; lock.unlock() }
                group.leave()
            }
            group.enter()
            deleteDocuments(in: db.collection("bloodTests").whereField("patientId", isEqualTo: user.uid)) { success in
                if !success { lock.lock(); hadError = true; lock.unlock() }
                group.leave()
            }
        }

        group.notify(queue: .main) { completion?(!hadError) }
    }

    private func deleteDocuments(in query: Query, completion: @escaping (Bool) -> Void) {
        query.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Query delete fetch error: \(error.localizedDescription)")
                completion(false); return
            }
            guard let docs = snapshot?.documents, !docs.isEmpty else { completion(true); return }

            let batch = self.db.batch()
            docs.forEach { batch.deleteDocument($0.reference) }
            batch.commit { error in
                if let error = error {
                    print("❌ Batch delete commit error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
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
            self.isAdminSession = false
            self.currentUser = nil
            self.appointments = []
            self.availableDoctors = []
            self.patientAppointments = []
            self.adminDoctors = []
            self.adminPatients = []
            self.adminAppointments = []
            self.patientPrescriptions = []
            self.patientBloodTests = []
        }
    }
}
