//
//  DigitalWalletView.swift
//  MediChain


import SwiftUI

struct DigitalWalletView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let qrGenerator = QRCodeGenerator()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Digital Identity")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 15) {
                // Generate QR based on the logged-in user's ID
                Image(uiImage: qrGenerator.generateQRCode(from: authViewModel.currentUser?.id ?? "Unknown_User"))
                    .interpolation(.none) // Keeps the QR code crisp and readable
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Text(authViewModel.currentUser?.fullName ?? "Patient Name")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Displays the first 8 characters of the unique ID
                Text("Patient ID: \(authViewModel.currentUser?.id.prefix(8) ?? "00000000")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(30)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
            .padding(.horizontal, 24)
            
            Text("Show this QR code to your healthcare provider to instantly share your medical history.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top, 40)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}
