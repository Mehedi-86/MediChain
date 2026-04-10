import SwiftUI

struct MyInfoView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    // NEW: Added fullName state
    @State private var fullName = ""
    @State private var bloodGroup = ""
    @State private var age = ""
    @State private var weight = ""
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Unknown"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        // CHANGED: This is now an editable TextField!
                        TextField("Full Name", text: $fullName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.primary)
                    }
                    HStack {
                        Text("Email")
                        Spacer()
                        // We keep Email read-only because changing a Firebase Auth email requires a special re-authentication flow
                        Text(authViewModel.currentUser?.email ?? "Unknown")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Medical Metrics")) {
                    Picker("Blood Group", selection: $bloodGroup) {
                        ForEach(bloodGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("e.g. 28", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("e.g. 70", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Button(action: {
                    // UPDATED: Now passes the fullName to the view model
                    authViewModel.updatePatientInfo(fullName: fullName, bloodGroup: bloodGroup, age: age, weight: weight)
                    dismiss()
                }) {
                    Text("Save Medical Info")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("My Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Pre-fill the form with existing data when the screen opens
                if let user = authViewModel.currentUser {
                    self.fullName = user.fullName ?? "" // Pre-fill the name
                    self.bloodGroup = user.bloodGroup ?? "Unknown"
                    self.age = user.age ?? ""
                    self.weight = user.weight ?? ""
                }
            }
        }
    }
}
