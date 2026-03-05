//
//  DoctorDashboardView.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI

struct DoctorDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var dailyLimit: Int = 5
    @State private var dutyStart = Date()
    @State private var dutyEnd = Date().addingTimeInterval(3600 * 2)
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    var body: some View {
        NavigationView {
            // THE FIX: A ZStack safely locks the background behind the content
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - Premium Profile Header
                        HStack(spacing: 15) {
                            Image(systemName: "stethoscope.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.indigo)
                                .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                // Smart fallback here as well
                                Text(authViewModel.currentUser?.fullName ?? authViewModel.currentUser?.email.components(separatedBy: "@").first?.capitalized ?? "Doctor")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // MARK: - Duty Settings Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.indigo)
                                Text("Shift Settings")
                                    .font(.headline)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Daily Patient Limit")
                                    .foregroundColor(.secondary)
                                Spacer()
                                TextField("5", value: $dailyLimit, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                                    .padding(6)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(8)
                            }
                            
                            HStack {
                                DatePicker("Start Time", selection: $dutyStart, displayedComponents: .hourAndMinute)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                DatePicker("End Time", selection: $dutyEnd, displayedComponents: .hourAndMinute)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                let startString = timeFormatter.string(from: dutyStart)
                                let endString = timeFormatter.string(from: dutyEnd)
                                authViewModel.updateDoctorDuty(limit: dailyLimit, start: startString, end: endString)
                            }) {
                                Text("Save Duty Settings")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.indigo)
                                    .cornerRadius(12)
                                    .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                        
                        // MARK: - Patient Queue Feed
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Today's Queue")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(authViewModel.appointments.count) Patients")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.indigo.opacity(0.1))
                                    .foregroundColor(.indigo)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            
                            if authViewModel.appointments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("No pending appointments. Take a break!")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                ForEach(authViewModel.appointments) { appt in
                                    PatientQueueCardView(appointment: appt)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 30)
                }
            }
            // All Navigation modifiers MUST be attached to the ZStack, not the ScrollView
            .navigationTitle("Doctor Portal")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let savedLimit = authViewModel.currentUser?.dailyLimit {
                    self.dailyLimit = savedLimit
                }
                if let startStr = authViewModel.currentUser?.dutyStart, let start = timeFormatter.date(from: startStr) {
                    self.dutyStart = start
                }
                if let endStr = authViewModel.currentUser?.dutyEnd, let end = timeFormatter.date(from: endStr) {
                    self.dutyEnd = end
                }
                
                authViewModel.fetchDoctorAppointments()
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
        // THE FIX: This prevents iOS from breaking the Nav Bar during login/logout swaps
        .navigationViewStyle(.stack)
    }
}

// MARK: - Custom Patient Queue Card UI
struct PatientQueueCardView: View {
    var appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // HEADER: Name & Serial Number
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.indigo)
                        .font(.title2)
                    
                    Text(appointment.patientName ?? "Unknown Patient")
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
            }
            
            Divider()
            
            // MIDDLE: Reason for visit
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.top, 2)
                
                Text(appointment.notes.isEmpty ? "No reason provided" : appointment.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // BOTTOM: Date and Time
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .font(.subheadline) // Slightly larger icon
                    Text(appointment.date.formatted(.dateTime.day().month().year()))
                        .font(.subheadline) // Upgraded from .caption to .subheadline
                        .fontWeight(.medium) // Added medium weight for better readability
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                        .font(.subheadline) // Slightly larger icon
                    Text(appointment.timeSlot ?? "Unknown Slot")
                        .font(.subheadline) // Upgraded from .caption to .subheadline
                        .fontWeight(.medium) // Added medium weight for better readability
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
