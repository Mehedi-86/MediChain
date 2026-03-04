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
    @State private var dutyEnd = Date().addingTimeInterval(3600 * 2) // Defaults to 2 hours later
    
    // Helper to format the Date object into a readable string like "7:00 PM"
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Duty Settings")) {
                        HStack {
                            Text("Daily Patient Limit")
                            Spacer()
                            TextField("5", value: $dailyLimit, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                        }
                        
                        // NEW: Dynamic Time Pickers
                        DatePicker("Shift Start", selection: $dutyStart, displayedComponents: .hourAndMinute)
                        DatePicker("Shift End", selection: $dutyEnd, displayedComponents: .hourAndMinute)
                        
                        Button(action: {
                            // Convert the selected Dates back to Strings to save to Firestore
                            let startString = timeFormatter.string(from: dutyStart)
                            let endString = timeFormatter.string(from: dutyEnd)
                            
                            authViewModel.updateDoctorDuty(limit: dailyLimit, start: startString, end: endString)
                        }) {
                            Label("Save Duty Settings", systemImage: "clock.badge.checkmark")
                                .fontWeight(.medium)
                        }
                    }
                    
                    Section(header: Text("Today's Patient Queue")) {
                        if authViewModel.appointments.isEmpty {
                            Text("No pending appointments.")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(authViewModel.appointments) { appt in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Patient: \(appt.patientId.prefix(6))...")
                                            .font(.headline)
                                        Text("Reason: \(appt.notes)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(appt.date.formatted(.dateTime.day().month()))
                                            .font(.caption)
                                            .bold()
                                        Text(appt.timeSlot ?? "Unknown Slot")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Doctor Portal")
            .onAppear {
                // Pre-fill settings with the doctor's currently saved data
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
                Button("Sign Out") {
                    authViewModel.signOut()
                }
            }
        }
    }
}
