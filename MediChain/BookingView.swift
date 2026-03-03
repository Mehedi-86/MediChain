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
    @State private var selectedDoctorId: String?
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Date & Time")) {
                    DatePicker("Appointment", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Select Available Doctor")) {
                    if authViewModel.allDoctors.isEmpty {
                        Text("No doctors available.")
                            .foregroundColor(.gray)
                    } else {
                        Picker("Doctor", selection: $selectedDoctorId) {
                            Text("Select a Doctor").tag(String?.none)
                            ForEach(authViewModel.allDoctors) { doctor in
                                // Shows the doctor's email as a name for now
                                Text(doctor.email.components(separatedBy: "@").first?.capitalized ?? "Doctor")
                                    .tag(String?.some(doctor.uid))
                            }
                        }
                    }
                }
                
                Section(header: Text("Appointment Notes")) {
                    TextField("E.g., Fever, Checkup", text: $notes)
                }
                
                Button(action: {
                    if let docId = selectedDoctorId {
                        authViewModel.scheduleAppointment(doctorId: docId, date: selectedDate, notes: notes)
                        dismiss()
                    }
                }) {
                    Text("Confirm Appointment")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedDoctorId == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedDoctorId == nil)
            }
            .navigationTitle("Request Appointment")
            .onAppear {
                authViewModel.fetchAllDoctors() // Fetch the list when the view opens
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
