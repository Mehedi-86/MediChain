// PatientDashboardView.swift
// MediChain

import SwiftUI
import PhotosUI

struct PatientDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showBookingSheet = false
    @State private var showScannerSheet = false
    @State private var showMyInfo = false
    @State private var showDigitalWallet = false
    @State private var showMedicalRecords = false          // NEW

    // MARK: - Appointment Detail (NEW)
    @State private var selectedAppointment: Appointment? = nil

    // MARK: - Profile Picture State
    @State private var showProfileMenu = false
    @State private var showPhotoPicker = false
    @State private var showFullScreenProfile = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

    // MARK: - Pagination State
    @State private var currentPage = 0
    private let itemsPerPage = 5

    var totalPages: Int {
        Int(ceil(Double(authViewModel.patientAppointments.count) / Double(itemsPerPage)))
    }

    var paginatedAppointments: [Appointment] {
        let start = currentPage * itemsPerPage
        if start >= authViewModel.patientAppointments.count && currentPage > 0 {
            DispatchQueue.main.async { currentPage -= 1 }
            return []
        }
        let end = min(start + itemsPerPage, authViewModel.patientAppointments.count)
        guard start < authViewModel.patientAppointments.count else { return [] }
        return Array(authViewModel.patientAppointments[start..<end])
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
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.blue)
                                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
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
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(authViewModel.currentUser?.fullName
                                     ?? authViewModel.currentUser?.email.components(separatedBy: "@").first?.capitalized
                                     ?? "Patient")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()

                            Button(action: { showDigitalWallet = true }) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                    .padding(10)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)

                        // MARK: - Action Buttons
                        // "Prescriptions" → OCR Scanner  |  "My Records" → text-based medical records (NEW)
                        HStack(spacing: 15) {
                            Button(action: { showScannerSheet = true }) {
                                ActionButton(title: "Scan Rx", icon: "doc.text.viewfinder", color: .teal)
                            }

                            Button(action: { showMedicalRecords = true }) {
                                ActionButton(title: "My Records", icon: "folder.fill.badge.plus", color: .purple)
                            }
                        }
                        .padding(.horizontal)

                        // MARK: - My Info
                        Button(action: { showMyInfo = true }) {
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                    .frame(width: 40, height: 40)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("My Medical Info")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("View and update your personal details")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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

                        // MARK: - Booking Banner
                        Button(action: { showBookingSheet = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Need to see a doctor?")
                                        .font(.headline).foregroundColor(.white)
                                    Text("Book a new telehealth session now.")
                                        .font(.subheadline).foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 30)).foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color(red: 0.2, green: 0.5, blue: 0.9)]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 5)
                        }
                        .padding(.horizontal)

                        // MARK: - Upcoming Appointments
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Upcoming Appointments")
                                .font(.title3).fontWeight(.bold)
                                .padding(.horizontal)

                            if authViewModel.patientAppointments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 40)).foregroundColor(.gray.opacity(0.5))
                                    Text("No appointments scheduled yet.")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 30)
                            } else {
                                ForEach(paginatedAppointments) { appt in
                                    // UPDATED: Card is now tappable to open detail view
                                    AppointmentCardView(appointment: appt) {
                                        authViewModel.cancelAppointment(appointment: appt)
                                    } onTap: {
                                        selectedAppointment = appt
                                    }
                                    .padding(.horizontal)
                                }

                                if totalPages > 1 {
                                    HStack {
                                        Button(action: { withAnimation { currentPage -= 1 } }) {
                                            Image(systemName: "chevron.left").font(.headline)
                                                .padding(12)
                                                .background(currentPage == 0 ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                                                .foregroundColor(currentPage == 0 ? .gray : .blue)
                                                .clipShape(Circle())
                                        }
                                        .disabled(currentPage == 0)

                                        Spacer()
                                        Text("Page \(currentPage + 1) of \(totalPages)")
                                            .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                                        Spacer()

                                        Button(action: { withAnimation { currentPage += 1 } }) {
                                            Image(systemName: "chevron.right").font(.headline)
                                                .padding(12)
                                                .background(currentPage >= totalPages - 1 ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                                                .foregroundColor(currentPage >= totalPages - 1 ? .gray : .blue)
                                                .clipShape(Circle())
                                        }
                                        .disabled(currentPage >= totalPages - 1)
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
            .navigationTitle("Patient Portal")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { authViewModel.fetchPatientAppointments() }
            .sheet(isPresented: $showBookingSheet) {
                BookingView().environmentObject(authViewModel)
            }
            .sheet(isPresented: $showMyInfo) {
                MyInfoView().environmentObject(authViewModel)
            }
            .sheet(isPresented: $showScannerSheet) {
                PrescriptionScannerView()
            }
            .sheet(isPresented: $showDigitalWallet) {
                DigitalWalletView().environmentObject(authViewModel)
            }
            .sheet(isPresented: $showMedicalRecords) {                     // NEW
                MedicalRecordsView().environmentObject(authViewModel)
            }
            .sheet(item: $selectedAppointment) { appt in                   // NEW
                AppointmentDetailView(appointment: appt)
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

// MARK: - Appointment Card (UPDATED: added onTap callback + "View Details" button)

struct AppointmentCardView: View {
    var appointment: Appointment
    var onCancel: () -> Void
    var onTap: () -> Void          // NEW

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.white).padding(8)
                        .background(Color.blue).clipShape(Circle())

                    Text(appointment.doctorName ?? "Unknown")
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

                Menu {
                    Button(role: .destructive, action: onCancel) {
                        Label("Cancel Appointment", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3).foregroundColor(.gray)
                        .padding(.leading, 8).padding(.vertical, 4)
                }
            }

            Divider()

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar").foregroundColor(.gray)
                    Text(appointment.date.formatted(.dateTime.day().month().year()))
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "clock").foregroundColor(.gray)
                    Text(appointment.timeSlot ?? "Unknown Slot")
                        .font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                }
            }

            // NEW: View Details / Prescription button
            Button(action: onTap) {
                HStack {
                    Image(systemName: appointment.prescriptionId != nil ? "cross.case.fill" : "doc.text")
                    Text(appointment.prescriptionId != nil ? "View Prescription" : "View Details")
                }
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(appointment.prescriptionId != nil ? .indigo : .blue)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background((appointment.prescriptionId != nil ? Color.indigo : Color.blue).opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.top, 2)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Action Button (unchanged)

struct ActionButton: View {
    var title: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.title2)
                .foregroundColor(color).frame(width: 50, height: 50)
                .background(color.opacity(0.15)).clipShape(Circle())
            Text(title).font(.caption).fontWeight(.medium).foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 15)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
