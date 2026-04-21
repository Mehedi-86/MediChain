// PatientDetailView.swift
// MediChain

import SwiftUI

struct PatientDetailView: View {
    var patient: MediUser
    var appointment: Appointment? = nil      // NEW: optional linked appointment

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    // MARK: - State for patient's medical records
    @State private var prescriptions: [PatientPrescription] = []
    @State private var bloodTests: [BloodTestRecord] = []
    @State private var isLoadingRecords = true

    // MARK: - State for writing a new prescription
    @State private var showWritePrescription = false
    @State private var expandedPrescriptionId: String? = nil
    @State private var expandedBloodTestId: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: - Profile Header
                    profileHeaderSection

                    // MARK: - Basic Info
                    basicInfoSection

                    // MARK: - Write Prescription Button
                    if appointment != nil {
                        Button {
                            showWritePrescription = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "cross.case.fill")
                                    .font(.headline)
                                Text("Write Prescription")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.indigo, .blue],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .indigo.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Patient's Prescriptions
                    prescriptionsSection

                    // MARK: - Patient's Blood Tests
                    bloodTestsSection
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Patient Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadPatientRecords() }
            .sheet(isPresented: $showWritePrescription) {
                WritePrescriptionSheet(
                    patientName: patient.fullName ?? patient.email,
                    appointmentId: appointment?.id
                )
                .environmentObject(authViewModel)
                .onDisappear {
                    // Refresh prescriptions after doctor writes one
                    loadPatientRecords()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Profile Header Section

    private var profileHeaderSection: some View {
        VStack(spacing: 12) {
            if let imageUrl = patient.profileImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .shadow(radius: 4)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable().frame(width: 80, height: 80)
                    .foregroundColor(.gray)
            }

            Text(patient.fullName ?? "Unknown Patient")
                .font(.title3).fontWeight(.bold)

            if let appt = appointment {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(appt.date.formatted(.dateTime.day().month().year()))
                    if let serial = appt.serialNumber {
                        Text("·  Serial #\(serial)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Medical Metrics", icon: "waveform.path.ecg")

            Group {
                PatientDetailRow(title: "Blood Group", value: patient.bloodGroup ?? "Not provided")
                Divider().padding(.leading, 16)
                PatientDetailRow(title: "Age", value: patient.age ?? "Not provided")
                Divider().padding(.leading, 16)
                PatientDetailRow(title: "Weight", value: patient.weight != nil ? "\(patient.weight!) kg" : "Not provided")
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    // MARK: - Prescriptions Section

    private var prescriptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Prescriptions", icon: "cross.case.fill")
                .padding(.horizontal)

            if isLoadingRecords {
                HStack { Spacer(); ProgressView(); Spacer() }.padding()
            } else if prescriptions.isEmpty {
                emptyRecordState(title: "No prescriptions on file", icon: "cross.case")
                    .padding(.horizontal)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(prescriptions) { prescription in
                        DoctorViewPrescriptionCard(
                            prescription: prescription,
                            isExpanded: expandedPrescriptionId == prescription.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                expandedPrescriptionId = expandedPrescriptionId == prescription.id ? nil : prescription.id
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Blood Tests Section

    private var bloodTestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Blood Tests", icon: "drop.fill")
                .padding(.horizontal)

            if isLoadingRecords {
                HStack { Spacer(); ProgressView(); Spacer() }.padding()
            } else if bloodTests.isEmpty {
                emptyRecordState(title: "No blood tests on file", icon: "drop")
                    .padding(.horizontal)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(bloodTests) { test in
                        DoctorViewBloodTestCard(
                            record: test,
                            isExpanded: expandedBloodTestId == test.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                expandedBloodTestId = expandedBloodTestId == test.id ? nil : test.id
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadPatientRecords() {
        isLoadingRecords = true
        let group = DispatchGroup()

        group.enter()
        authViewModel.fetchPrescriptionsForPatient(patientId: patient.uid) { items in
            self.prescriptions = items
            group.leave()
        }

        group.enter()
        authViewModel.fetchBloodTestsForPatient(patientId: patient.uid) { items in
            self.bloodTests = items
            group.leave()
        }

        group.notify(queue: .main) {
            self.isLoadingRecords = false
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }

    private func emptyRecordState(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.secondary)
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Spacer()
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Detail Row

struct PatientDetailRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title).foregroundColor(.primary)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Doctor's read-only Prescription Card

private struct DoctorViewPrescriptionCard: View {
    let prescription: PatientPrescription
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: prescription.isFromDoctor ? "stethoscope" : "person.fill")
                        .font(.subheadline)
                        .foregroundColor(prescription.isFromDoctor ? .indigo : .blue)
                        .frame(width: 32, height: 32)
                        .background((prescription.isFromDoctor ? Color.indigo : Color.blue).opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(prescription.title)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(prescription.isFromDoctor
                             ? "By \(prescription.doctorName ?? "Doctor")"
                             : "Added by patient")
                            .font(.caption).foregroundColor(.secondary)

                        Text(prescription.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2).foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                Text(prescription.content)
                    .font(.body).foregroundColor(.primary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(prescription.isFromDoctor ? Color.indigo.opacity(0.2) : Color.blue.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Doctor's read-only Blood Test Card

private struct DoctorViewBloodTestCard: View {
    let record: BloodTestRecord
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.subheadline).foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.testName)
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                        Text("Blood Test")
                            .font(.caption).foregroundColor(.secondary)
                        Text(record.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2).foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                Text(record.content)
                    .font(.body).foregroundColor(.primary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.red.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Write Prescription Sheet

struct WritePrescriptionSheet: View {
    let patientName: String
    let appointmentId: String?

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var isSaving = false
    @State private var showError = false

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient")) {
                    HStack {
                        Image(systemName: "person.fill").foregroundColor(.secondary)
                        Text(patientName).foregroundColor(.primary)
                    }
                }

                Section(header: Text("Prescription")) {
                    TextField("Title  (e.g., Post-Consultation Rx)", text: $title)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prescription Details")
                            .font(.caption).foregroundColor(.secondary)

                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Text("This prescription will be saved to the patient's profile and linked to this appointment. The patient will see it when they tap on their appointment.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Write Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving { ProgressView() }
                        else { Text("Save").fontWeight(.bold) }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .alert("Could not save", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please fill in both fields and try again.")
            }
        }
    }

    private func save() {
        guard let patientId = resolvePatientId() else { showError = true; return }
        isSaving = true
        authViewModel.addDoctorPrescription(
            patientId: patientId,
            appointmentId: appointmentId,
            title: title,
            content: content
        ) { success in
            isSaving = false
            if success { dismiss() } else { showError = true }
        }
    }

    /// Resolves patientId from the linked appointment stored in authViewModel
    private func resolvePatientId() -> String? {
        guard let appointmentId else { return nil }
        return authViewModel.appointments.first(where: { $0.id == appointmentId })?.patientId
            ?? authViewModel.adminAppointments.first(where: { $0.id == appointmentId })?.patientId
    }
}
