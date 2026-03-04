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
            List {
                Section(header: Text("My Medical Timeline")) {
                    Label("View Scanned Prescriptions", systemImage: "doc.text.viewfinder")
                    Label("Export Health Report (PDF)", systemImage: "arrow.up.doc")
                }
                
                Section(header: Text("Upcoming Appointments")) {
                    if authViewModel.patientAppointments.isEmpty {
                        Text("No appointments scheduled yet.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(authViewModel.patientAppointments) { appt in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Appt with Dr. \(appt.doctorName ?? "Unknown")")
                                        .font(.headline)
                                    
                                    // Combine Date and Duty Hours here
                                    Text("\(appt.date.formatted(.dateTime.day().month().year())) • \(appt.timeSlot ?? "7:00 PM - 9:00 PM")")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    authViewModel.cancelAppointment(appointment: appt)
                                }) {
                                    Text("Cancel")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("Telehealth Services")) {
                    Button(action: {
                        showBookingSheet = true
                    }) {
                        Label("Request New Appointment", systemImage: "calendar.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Patient Portal")
            .onAppear {
                authViewModel.fetchPatientAppointments()
            }
            .sheet(isPresented: $showBookingSheet) {
                BookingView()
                    .environmentObject(authViewModel)
            }
            .toolbar {
                Button("Sign Out") {
                    authViewModel.signOut()
                }
            }
        }
    }
}
