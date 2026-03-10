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
    
    // NEW: Alert State Variables
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Visit Date")) {
                    DatePicker("Appointment Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .onChange(of: selectedDate) { newDate in
                            selectedDoctor = nil
                            authViewModel.fetchAvailableDoctors(for: newDate)
                        }
                        .disabled(selectedDoctor != nil)
                }
                
                Section(header: Text("Select Available Doctor")) {
                    if authViewModel.availableDoctors.isEmpty {
                        Text("No doctors available for this date.")
                            .foregroundColor(.gray)
                    } else {
                        Picker("Doctor", selection: $selectedDoctor) {
                            Text("Select a Doctor").tag(nil as MediUser?)
                            
                            ForEach(authViewModel.availableDoctors, id: \.self) { doctor in
                                                            
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
