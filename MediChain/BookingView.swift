//
//  BookingView.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI

struct BookingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedDoctor: MediUser?
    @State private var notes = ""
    
    // NEW: Region Filter State
    @State private var selectedRegion: String = "All Regions"
    
    // Alert State Variables
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // MARK: - Computed Properties for Filtering
    
    // 1. Extracts unique regions from the currently available doctors
    var availableRegions: [String] {
        var regions = ["All Regions"]
        // Get all regions, remove nils, remove empties, and remove duplicates using Set
        let docRegions = Set(authViewModel.availableDoctors.compactMap { $0.region }.filter { !$0.isEmpty })
        regions.append(contentsOf: docRegions.sorted())
        return regions
    }
    
    // 2. Filters the doctor list based on the selected region
    var filteredDoctors: [MediUser] {
        if selectedRegion == "All Regions" {
            return authViewModel.availableDoctors
        } else {
            return authViewModel.availableDoctors.filter { $0.region == selectedRegion }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Visit Date")) {
                    DatePicker("Appointment Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .onChange(of: selectedDate) { newDate in
                            // Reset everything when the date changes
                            selectedDoctor = nil
                            selectedRegion = "All Regions"
                            authViewModel.fetchAvailableDoctors(for: newDate)
                        }
                        .disabled(selectedDoctor != nil) // Prevent changing date if doctor is already picked
                }
                
                // MARK: - NEW: Region Filter Section
                // Only show the region filter if there are actually doctors available on this date
                if !authViewModel.availableDoctors.isEmpty {
                    Section(header: Text("Filter by Region")) {
                        Picker("Region", selection: $selectedRegion) {
                            ForEach(availableRegions, id: \.self) { region in
                                Text(region).tag(region)
                            }
                        }
                        .onChange(of: selectedRegion) { _ in
                            // If the user changes the region, reset their selected doctor
                            selectedDoctor = nil
                        }
                    }
                }
                
                Section(header: Text("Select Available Doctor")) {
                    if filteredDoctors.isEmpty {
                        // Dynamic empty message
                        Text(authViewModel.availableDoctors.isEmpty ? "No doctors available for this date." : "No doctors available in this region.")
                            .foregroundColor(.gray)
                    } else {
                        // Uses the FILTERED doctors array instead of the main one
                        Picker("Doctor", selection: $selectedDoctor) {
                            Text("Select a Doctor").tag(nil as MediUser?)
                            
                            ForEach(filteredDoctors, id: \.self) { doctor in
                                                                               
                                let rawName = doctor.fullName ?? doctor.email.components(separatedBy: "@").first?.capitalized ?? "Doctor"
                                let specialty = doctor.specialty ?? "General Physician"
                                
                                let docName = rawName.hasPrefix("Dr.") ? rawName : "Dr. \(rawName)"
                                
                            
                                Text("\(docName)\n\(specialty)")
                                    .tag(doctor as MediUser?)
                                
                                
                            }
                        }
                    }
                }
                
                Section(header: Text("Appointment Notes")) {
                    TextField("E.g., Fever, Checkup", text: $notes)
                }
                
                Button(action: {
                    if let doctor = selectedDoctor {
                        let rawName = doctor.fullName ?? doctor.email.components(separatedBy: "@").first?.capitalized ?? "Doctor"
                        let docName = rawName.hasPrefix("Dr.") ? rawName : "Dr. \(rawName)"
                        let start = doctor.dutyStart ?? "7:00 PM"
                        let end = doctor.dutyEnd ?? "9:00 PM"
                        let slot = "\(start) - \(end)"
                        
                        // Handle the completion block
                        authViewModel.scheduleAppointment(doctorId: doctor.uid, doctorName: docName, timeSlot: slot, date: selectedDate, notes: notes) { success, message in
                            if success {
                                dismiss() // Close sheet if booked
                            } else {
                                alertMessage = message // Show error if duplicate date
                                showAlert = true
                            }
                        }
                    }
                }) {
                    Text("Confirm Appointment")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedDoctor == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedDoctor == nil)
            }
            .navigationTitle("Request Appointment")
            .onAppear {
                authViewModel.fetchAvailableDoctors(for: selectedDate)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Displays the duplicate booking error
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Booking Unavailable"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
