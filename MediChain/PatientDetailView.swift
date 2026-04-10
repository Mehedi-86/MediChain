import SwiftUI

struct PatientDetailView: View {
    var patient: MediUser
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Profile Picture Section
                Section {
                    HStack {
                        Spacer()
                        if let imageUrl = patient.profileImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .listRowBackground(Color.clear)
                
                // Details Section - Email Removed for Privacy!
                Section(header: Text("Account Details")) {
                    DetailRow(title: "Name", value: patient.fullName ?? "Unknown")
                }
                
                Section(header: Text("Medical Metrics")) {
                    DetailRow(title: "Blood Group", value: patient.bloodGroup ?? "Not provided")
                    DetailRow(title: "Age", value: patient.age ?? "Not provided")
                    DetailRow(title: "Weight", value: patient.weight != nil ? "\(patient.weight!) kg" : "Not provided")
                }
            }
            .navigationTitle("Patient Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// A small helper to make the rows look clean
struct DetailRow: View {
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title).foregroundColor(.primary)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}
