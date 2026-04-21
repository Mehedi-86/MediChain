// DoctorDashboardView.swift
// MediChain

import SwiftUI
import PhotosUI

// NEW: Wrapper so we can pass both patient and appointment to PatientDetailView
struct PatientProfileContext: Identifiable {
    let id = UUID()
    let patient: MediUser
    let appointment: Appointment
}

struct DoctorDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    // MARK: - Profile State
    @State private var showMyInfo = false
    @State private var showProfileMenu = false
    @State private var showPhotoPicker = false
    @State private var showFullScreenProfile = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

    // UPDATED: holds both the patient and their linked appointment
    @State private var selectedPatientContext: PatientProfileContext? = nil

    // MARK: - Duty Settings State
    @State private var dailyLimit: Int = 5
    @State private var dutyStart = Date()
    @State private var dutyEnd = Date().addingTimeInterval(3600 * 2)
    @State private var selectedSpecialty: String = "Gen. Physician"
    let specialties = ["Gen. Physician", "Cardiologist", "Dermatologist",
                       "Endocrinologist", "Neurologist", "Pediatrician",
                       "Orthopedic", "Psychiatrist"]

    // MARK: - Date-Based Pagination State
    @State private var currentPageIndex = 0

    var uniqueDates: [Date] {
        let allDates = authViewModel.appointments.map { Calendar.current.startOfDay(for: $0.date) }
        return Array(Set(allDates)).sorted()
    }

    var currentDayAppointments: [Appointment] {
        guard uniqueDates.indices.contains(currentPageIndex) else { return [] }
        let targetDate = uniqueDates[currentPageIndex]
        return authViewModel.appointments.filter {
            Calendar.current.startOfDay(for: $0.date) == targetDate
        }
    }

    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Profile Header
                        HStack(spacing: 15) {
                            Button(action: { showProfileMenu = true }) {
                                if let image = profileImage {
                                    Image(uiImage: image)
                                        .resizable().scaledToFill()
                                        .frame(width: 60, height: 60).clipShape(Circle())
                                        .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 3)
                                } else {
                                    Image(systemName: "stethoscope.circle.fill")
                                        .resizable().frame(width: 60, height: 60)
                                        .foregroundColor(.indigo)
                                        .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                            }
                            .confirmationDialog("Profile Picture", isPresented: $showProfileMenu) {
                                if profileImage != nil {
                                    Button("View profile picture") { showFullScreenProfile = true }
                                    Button("Set a profile picture") { showPhotoPicker = true }
                                } else {
                                    Button("Set a profile picture") { showPhotoPicker = true }
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
                            .onChange(of: selectedPhotoItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            self.profileImage = uiImage
                                            authViewModel.uploadProfilePicture(imageData: data)
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,")
                                    .font(.subheadline).foregroundColor(.secondary)
                                Text(authViewModel.currentUser?.fullName
                                     ?? authViewModel.currentUser?.email.components(separatedBy: "@").first?.capitalized
                                     ?? "Doctor")
                                    .font(.title2).fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.horizontal).padding(.top, 10)

                        // MARK: - My Info
                        Button(action: { showMyInfo = true }) {
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .font(.title2).foregroundColor(.orange)
                                    .frame(width: 40, height: 40)
                                    .background(Color.orange.opacity(0.15)).clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("My Personal Info")
                                        .font(.headline).foregroundColor(.primary)
                                    Text("View and update your personal details")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)

                        // MARK: - Duty Settings
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "gearshape.fill").foregroundColor(.indigo)
                                Text("Shift Settings").font(.headline)
                            }
                            Divider()

                            HStack {
                                Text("Specialty").foregroundColor(.secondary)
                                Spacer()
                                Picker("Specialty", selection: $selectedSpecialty) {
                                    ForEach(specialties, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu).tint(.indigo)
                            }

                            HStack {
                                Text("Daily Patient Limit").foregroundColor(.secondary)
                                Spacer()
                                TextField("5", value: $dailyLimit, formatter: NumberFormatter())
                                    .keyboardType(.numberPad).multilineTextAlignment(.center)
                                    .frame(width: 60).padding(6)
                                    .background(Color(UIColor.tertiarySystemFill)).cornerRadius(8)
                            }

                            DatePicker("Start Time", selection: $dutyStart, displayedComponents: .hourAndMinute)
                                .foregroundColor(.secondary)
                            DatePicker("End Time", selection: $dutyEnd, displayedComponents: .hourAndMinute)
                                .foregroundColor(.secondary)

                            Button(action: {
                                let startString = timeFormatter.string(from: dutyStart)
                                let endString = timeFormatter.string(from: dutyEnd)
                                authViewModel.updateDoctorDuty(limit: dailyLimit, start: startString,
                                                               end: endString, specialty: selectedSpecialty)
                            }) {
                                Text("Save Duty Settings")
                                    .font(.headline).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding()
                                    .background(Color.indigo).cornerRadius(12)
                                    .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)

                        // MARK: - Patient Queue
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                if uniqueDates.indices.contains(currentPageIndex) {
                                    let viewedDate = uniqueDates[currentPageIndex]
                                    Text(Calendar.current.isDateInToday(viewedDate)
                                         ? "Today's Queue"
                                         : "Queue for \(viewedDate.formatted(.dateTime.day().month()))")
                                        .font(.title3).fontWeight(.bold)
                                } else {
                                    Text("Patient Queue").font(.title3).fontWeight(.bold)
                                }

                                Spacer()
                                Text("\(currentDayAppointments.count) Patients")
                                    .font(.caption).fontWeight(.bold)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.indigo.opacity(0.1))
                                    .foregroundColor(.indigo).cornerRadius(10)
                            }
                            .padding(.horizontal)

                            if authViewModel.appointments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .font(.system(size: 40)).foregroundColor(.gray.opacity(0.5))
                                    Text("No pending appointments. Take a break!")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 30)
                            } else {
                                ForEach(currentDayAppointments) { appt in
                                    PatientQueueCardView(appointment: appt) {
                                        // UPDATED: Pass both patient and appointment
                                        authViewModel.fetchUserDetails(uid: appt.patientId) { fetchedUser in
                                            if let user = fetchedUser {
                                                self.selectedPatientContext = PatientProfileContext(
                                                    patient: user,
                                                    appointment: appt
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }

                                if uniqueDates.count > 1 {
                                    HStack {
                                        Button(action: { withAnimation { currentPageIndex -= 1 } }) {
                                            Image(systemName: "chevron.left").font(.headline)
                                                .padding(12)
                                                .background(currentPageIndex == 0
                                                            ? Color.gray.opacity(0.2)
                                                            : Color.indigo.opacity(0.1))
                                                .foregroundColor(currentPageIndex == 0 ? .gray : .indigo)
                                                .clipShape(Circle())
                                        }
                                        .disabled(currentPageIndex == 0)

                                        Spacer()
                                        Text(uniqueDates[currentPageIndex]
                                            .formatted(.dateTime.weekday(.wide).day().month()))
                                            .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                                        Spacer()

                                        Button(action: { withAnimation { currentPageIndex += 1 } }) {
                                            Image(systemName: "chevron.right").font(.headline)
                                                .padding(12)
                                                .background(currentPageIndex >= uniqueDates.count - 1
                                                            ? Color.gray.opacity(0.2)
                                                            : Color.indigo.opacity(0.1))
                                                .foregroundColor(currentPageIndex >= uniqueDates.count - 1 ? .gray : .indigo)
                                                .clipShape(Circle())
                                        }
                                        .disabled(currentPageIndex >= uniqueDates.count - 1)
                                    }
                                    .padding(.horizontal, 20).padding(.top, 10)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Doctor Portal")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let savedLimit = authViewModel.currentUser?.dailyLimit { self.dailyLimit = savedLimit }
                if let savedSpecialty = authViewModel.currentUser?.specialty { self.selectedSpecialty = savedSpecialty }
                if let endStr = authViewModel.currentUser?.dutyEnd,
                   let end = timeFormatter.date(from: endStr) { self.dutyEnd = end }
                authViewModel.fetchDoctorAppointments()
            }
            .onChange(of: uniqueDates) { newDates in
                if currentPageIndex >= newDates.count { currentPageIndex = max(0, newDates.count - 1) }
            }
            .sheet(isPresented: $showMyInfo) {
                MyInfoView().environmentObject(authViewModel)
            }
            // UPDATED: Sheet now passes appointment context to PatientDetailView
            .sheet(item: $selectedPatientContext) { context in
                PatientDetailView(patient: context.patient, appointment: context.appointment)
                    .environmentObject(authViewModel)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { authViewModel.signOut() }) {
                        Text("Sign Out").fontWeight(.bold).foregroundColor(.red)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $showFullScreenProfile) {
            if let image = profileImage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showFullScreenProfile = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.largeTitle).foregroundColor(.white.opacity(0.7)).padding()
                            }
                        }
                        Spacer()
                    }
                    .zIndex(1)
                    Image(uiImage: image).resizable().scaledToFit().ignoresSafeArea()
                }
            }
        }
    }
}

// MARK: - Patient Queue Card (unchanged interface, updated label)

struct PatientQueueCardView: View {
    var appointment: Appointment
    var onViewProfile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.indigo).font(.title2)
                    Text(appointment.patientName ?? "Unknown Patient")
                        .font(.headline).foregroundColor(.primary)
                }
                Spacer()
                if let serial = appointment.serialNumber {
                    Text("Serial: #\(serial)")
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange).cornerRadius(8)
                }
            }

            Divider()

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "doc.text.fill").foregroundColor(.gray)
                    .font(.subheadline).padding(.top, 2)
                Text(appointment.notes.isEmpty ? "No reason provided" : appointment.notes)
                    .font(.subheadline).foregroundColor(.secondary)
            }

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar").foregroundColor(.gray).font(.subheadline)
                    Text(appointment.date.formatted(.dateTime.day().month().year()))
                        .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "clock").foregroundColor(.gray).font(.subheadline)
                    Text(appointment.timeSlot ?? "Unknown Slot")
                        .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary).lineLimit(1)
                }
            }

            // "View Patient Profile" opens profile + patient records + write prescription
            Button(action: onViewProfile) {
                HStack {
                    Image(systemName: "person.text.rectangle")
                    Text("View Patient & Write Prescription")          // updated label
                }
                .font(.subheadline).fontWeight(.medium).foregroundColor(.indigo)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(Color.indigo.opacity(0.1)).cornerRadius(10)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
