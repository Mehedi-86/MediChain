//
//  FDAInfoCard.swift
//  MediChain
//
//  Created by mehedi hasan on 10/3/26.
//

import SwiftUI

struct FDAInfoCard: View {
    let drugDetails: FDADrugDetail
    let medicineName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "cross.case.fill")
                    .foregroundColor(.blue)
                Text("Official FDA Information: \(medicineName.capitalized)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            // Purpose Section
            if let purpose = drugDetails.purpose?.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💊 Purpose")
                        .font(.subheadline)
                        .bold()
                    Text(purpose)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            // Dosage Section
            if let dosage = drugDetails.dosageAndAdministration?.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⏱️ Dosage & Administration")
                        .font(.subheadline)
                        .bold()
                    Text(dosage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            // Warnings Section
            if let warnings = drugDetails.warnings?.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚠️ Warnings")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.red)
                    Text(warnings)
                        .font(.footnote)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}
