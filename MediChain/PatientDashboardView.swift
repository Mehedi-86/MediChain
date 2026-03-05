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
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // MARK: - Action Buttons
                        HStack(spacing: 15) {
                            ActionButton(title: "Prescriptions", icon: "doc.text.viewfinder", color: .teal)
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
                        
                        // MARK: - Floating Appointments Feed
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
                                ForEach(authViewModel.patientAppointments) { appt in
                                    AppointmentCardView(appointment: appt) {
                                        authViewModel.cancelAppointment(appointment: appt)
                                    }
                                    .padding(.horizontal)
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
            
            // HEADER ROW
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
                
                // THE FIX: iOS Native 3-Dot Menu
                Menu {
                    Button(role: .destructive, action: onCancel) {
                        Label("Cancel Appointment", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.gray)
                        // Adding padding makes the invisible tap target larger and easier to hit
                        .padding(.leading, 8)
                        .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            // FOOTER ROW (Date & Time perfectly horizontal)
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text(appointment.date.formatted(.dateTime.day().month().year()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer() // This pushes the time to the far right so they never collide
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text(appointment.timeSlot ?? "Unknown Slot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1) // Forces the text to stay on exactly one horizontal line
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
