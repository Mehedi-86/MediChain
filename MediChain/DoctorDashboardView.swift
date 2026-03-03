//
//  DoctorDashboardView.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI

struct DoctorDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Step 2: Make the Doctor Portal Dynamic
                    Section(header: Text("Today's Patient Queue")) {
                        if authViewModel.appointments.isEmpty {
                            Text("No pending appointments.")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(authViewModel.appointments) { appt in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Patient ID: \(appt.patientId)")
                                            .font(.headline)
                                        Text("Status: \(appt.status)")
                                            .foregroundColor(.orange)
                                    }
                                    Spacer()
                                    Text(appt.date, style: .time)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Doctor Portal")
            .onAppear {
                authViewModel.fetchDoctorAppointments() // Trigger the fetch when screen loads
            }
            .toolbar {
                Button("Sign Out") {
                    authViewModel.signOut()
                }
            }
        }
    }
}
