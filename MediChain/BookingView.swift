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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Visit Date")) {
                    DatePicker("Appointment Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .onChange(of: selectedDate) { newDate in
                            // FAIL-SAFE: Clear the selected doctor if the date changes
                            selectedDoctor = nil
                            
                            authViewModel.fetchAvailableDoctors(for: newDate)
                        }
                        // THE FIX: Lock the date picker if a doctor is currently selected
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
                                Text(doctor.email.components(separatedBy: "@").first?.capitalized ?? "Doctor")
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
                        let docName = doctor.email.components(separatedBy: "@").first?.capitalized ?? "Doctor"
                        
                        let start = doctor.dutyStart ?? "7:00 PM"
                        let end = doctor.dutyEnd ?? "9:00 PM"
                        let slot = "\(start) - \(end)"
                        
                        authViewModel.scheduleAppointment(doctorId: doctor.uid, doctorName: docName, timeSlot: slot, date: selectedDate, notes: notes)
                        dismiss()
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
        }
    }
}
