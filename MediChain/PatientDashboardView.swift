//
//  PatientDashboardView.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI

struct PatientDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showBookingSheet = false
    @State private var showScannerSheet = false
    
    // STEP 1: Add the State Variable for the digital wallet
    @State private var showDigitalWallet = false
    
    // MARK: - Pagination State
    @State private var currentPage = 0
    private let itemsPerPage = 5
    
    // MARK: - Computed Pagination Variables
    var totalPages: Int {
        // Calculates how many pages we need (e.g., 6 items / 5 = 2 pages)
        Int(ceil(Double(authViewModel.patientAppointments.count) / Double(itemsPerPage)))
    }
    
    var paginatedAppointments: [Appointment] {
        let start = currentPage * itemsPerPage
        // Safety check if an appointment is canceled and the page becomes empty
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
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - Premium Profile Header
                        HStack(spacing: 15) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(authViewModel.currentUser?.fullName ?? authViewModel.currentUser?.email.components(separatedBy: "@").first?.capitalized ?? "Patient")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            
                            // STEP 2: The new QR Code Button
                            Button(action: {
                                showDigitalWallet = true
                            }) {
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
                        HStack(spacing: 15) {
                            
                            Button(action: {
                                showScannerSheet = true
                            }) {
                                ActionButton(title: "Prescriptions", icon: "doc.text.viewfinder", color: .teal)
                            }
                            
                            ActionButton(title: "Health Report", icon: "arrow.up.doc.fill", color: .purple)
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Telehealth Booking Area
                        Button(action: {
                            showBookingSheet = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Need to see a doctor?")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Book a new telehealth session now.")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color(red: 0.2, green: 0.5, blue: 0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Floating Appointments Feed (Paginated)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Upcoming Appointments")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if authViewModel.patientAppointments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("No appointments scheduled yet.")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                // Feed uses the paginated array instead of the full array!
                                ForEach(paginatedAppointments) { appt in
                                    AppointmentCardView(appointment: appt) {
                                        authViewModel.cancelAppointment(appointment: appt)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // MARK: - Pagination Controls
                                if totalPages > 1 {
                                    HStack {
                                        // Previous Button
                                        Button(action: {
                                            withAnimation { currentPage -= 1 }
                                        }) {
                                            Image(systemName: "chevron.left")
                                                .font(.headline)
                                                .padding(12)
                                                .background(currentPage == 0 ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                                                .foregroundColor(currentPage == 0 ? .gray : .blue)
                                                .clipShape(Circle())
                                        }
                                        .disabled(currentPage == 0)
                                        
                                        Spacer()
                                        
                                        // Page Indicator
                                        Text("Page \(currentPage + 1) of \(totalPages)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        // Next Button
                                        Button(action: {
                                            withAnimation { currentPage += 1 }
                                        }) {
                                            Image(systemName: "chevron.right")
                                                .font(.headline)
                                                .padding(12)
                                                .background(currentPage >= totalPages - 1 ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                                                .foregroundColor(currentPage >= totalPages - 1 ? .gray : .blue)
                                                .clipShape(Circle())
                                        }
                                        .disabled(currentPage >= totalPages - 1)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
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
            .onAppear {
                authViewModel.fetchPatientAppointments()
            }
            .sheet(isPresented: $showBookingSheet) {
                BookingView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showScannerSheet) {
                PrescriptionScannerView()
            }
            // STEP 3: Attach the Sheet for the Digital Wallet
            .sheet(isPresented: $showDigitalWallet) {
                DigitalWalletView()
                    .environmentObject(authViewModel)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { authViewModel.signOut() }) {
                        Text("Sign Out")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Custom Appointment Card UI
struct AppointmentCardView: View {
    var appointment: Appointment
    var onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .clipShape(Circle())
                    
                    Text("Dr. \(appointment.doctorName ?? "Unknown")")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let serial = appointment.serialNumber {
                    Text("Serial: #\(serial)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                
                Menu {
                    Button(role: .destructive, action: onCancel) {
                        Label("Cancel Appointment", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                        .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text(appointment.date.formatted(.dateTime.day().month().year()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text(appointment.timeSlot ?? "Unknown Slot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Reusable Square Button
struct ActionButton: View {
    var title: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
