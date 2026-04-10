//
//  LoginView.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var region = "" // NEW: Region state variable
    @State private var isLoginMode = true
    @State private var selectedRole: UserRole = .patient
    
    // Form Validation Logic Updated to include Region for Doctors
    var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty
        } else {
            if selectedRole == .doctor {
                return !email.isEmpty && !password.isEmpty && !fullName.isEmpty && !region.isEmpty
            } else {
                return !email.isEmpty && !password.isEmpty && !fullName.isEmpty
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // MARK: - Header / Logo
                    VStack(spacing: 12) {
                        Image(systemName: "cross.case.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.blue)
                            .padding(.top, 40)
                        
                        Text("MediChain")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                        
                        Text(isLoginMode ? "Sign in to your health portal" : "Create an account to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 10)
                    
                    // MARK: - Mode Selector
                    Picker("Login Mode", selection: $isLoginMode) {
                        Text("Login").tag(true)
                        Text("Create Account").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // MARK: - Input Fields
                    VStack(spacing: 16) {
                        if !isLoginMode {
                            // Custom Name Field
                            CustomTextField(icon: "person.fill", placeholder: "Full Name (e.g., Dr. Mehedi)", text: $fullName)
                            
                            // Role Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("I am a...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                
                                Picker("Role", selection: $selectedRole) {
                                    Text("Patient").tag(UserRole.patient)
                                    Text("Doctor").tag(UserRole.doctor)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding(.bottom, 8)
                        }
                        
                        // Custom Email Field
                        CustomTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, isEmail: true)
                        
                        // Custom Password Field
                        CustomSecureField(icon: "lock.fill", placeholder: "Password", text: $password)
                        
                        // MARK: - NEW: Region Field (Only for Doctors creating an account)
                        if !isLoginMode && selectedRole == .doctor {
                            CustomTextField(icon: "mappin.and.ellipse", placeholder: "Region (e.g., Khulna, Bangladesh)", text: $region)
                                .transition(.move(edge: .top).combined(with: .opacity)) // Smooth slide-in
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut, value: selectedRole) // Animates the region field appearing/disappearing
                    
                    // MARK: - Action Button
                    Button(action: {
                        if isLoginMode {
                            authViewModel.signIn(email: email, password: password)
                        } else {
                            // TODO: Azrof needs to update the signUp function in AuthViewModel
                            // to accept the new 'region' parameter!
                            // Example: authViewModel.signUp(email: email, password: password, fullName: fullName, role: selectedRole, region: region)
                            
                            authViewModel.signUp(email: email, password: password, fullName: fullName, role: selectedRole, region: region)
                        }
                    }) {
                        Text(isLoginMode ? "Sign In" : "Create Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            // Changes color based on validation
                            .background(isFormValid ? Color.blue : Color.blue.opacity(0.5))
                            .cornerRadius(12)
                            .shadow(color: isFormValid ? Color.blue.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                    }
                    .disabled(!isFormValid) // Prevents clicking if fields are empty
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .animation(.easeInOut, value: isLoginMode) // Animates the layout changes for Login vs Create
            }
        }
    }
}

// MARK: - Reusable Custom UI Components

// A reusable struct to make text fields look modern and consistent
struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isEmail: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isEmail {
                TextField(placeholder, text: $text)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            } else {
                TextField(placeholder, text: $text)
                    .autocapitalization(.words)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground)) // Automatically handles light/dark mode
        .cornerRadius(12)
    }
}

// A reusable struct for the password field
struct CustomSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
