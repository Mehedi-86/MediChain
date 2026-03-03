//
//  LoginView.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .patient
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("MediChain Access")
                    .font(.largeTitle.bold())
                
                Picker("Select Role", selection: $selectedRole) {
                    Text("Patient").tag(UserRole.patient)
                    Text("Doctor").tag(UserRole.doctor)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Password (min. 6 chars)", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Primary Action: Register
                Button(action: {
                    viewModel.signUp(email: email, password: password, role: selectedRole)
                }) {
                    Text("Register & Enter Portal")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(password.count >= 6 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(password.count < 6)
                
                // Secondary Action: Login for existing users
                Button(action: {
                    viewModel.signIn(email: email, password: password)
                }) {
                    Text("Already have an account? Sign In")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
