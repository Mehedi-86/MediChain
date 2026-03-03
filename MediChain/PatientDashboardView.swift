//
//  PatientDashboardView.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI

// Updated PatientDashboardView.swift
struct PatientDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showBookingSheet = false // Controls the calendar popup
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("My Medical Timeline")) {
                    Label("View Scanned Prescriptions", systemImage: "doc.text.viewfinder")
                    Label("Export Health Report (PDF)", systemImage: "arrow.up.doc")
                }
                
                Section(header: Text("Telehealth Services")) {
                    Button(action: {
                        showBookingSheet = true // Triggers the booking flow
                    }) {
                        Label("Request New Appointment", systemImage: "calendar.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Patient Portal")
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
