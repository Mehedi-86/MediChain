// MedicalRecordsView.swift
// MediChain

import SwiftUI

enum MedicalRecordTab: String, CaseIterable {
    case prescriptions = "Prescriptions"
    case bloodTests    = "Blood Tests"

    var icon: String {
        switch self {
        case .prescriptions: return "cross.case.fill"
        case .bloodTests:    return "drop.fill"
        }
    }
}

struct MedicalRecordsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab: MedicalRecordTab = .prescriptions
    @State private var showAddSheet = false
    @State private var expandedRecordId: String? = nil

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Tab Selector
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(MedicalRecordTab.allCases, id: \.self) { tab in
                            Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // MARK: - Content
                    ScrollView {
                        VStack(spacing: 12) {
                            if selectedTab == .prescriptions {
                                prescriptionsContent
                            } else {
                                bloodTestsContent
                            }
                        }
                        .padding()
                        .padding(.bottom, 80) // room for FAB
                    }
                }

                // MARK: - Floating Add Button
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: selectedTab == .prescriptions ? [.blue, .indigo] : [.red, .pink],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(24)
            }
            .navigationTitle("My Medical Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                authViewModel.fetchPatientPrescriptions()
                authViewModel.fetchPatientBloodTests()
            }
            .sheet(isPresented: $showAddSheet) {
                if selectedTab == .prescriptions {
                    AddPrescriptionSheet()
                        .environmentObject(authViewModel)
                } else {
                    AddBloodTestSheet()
                        .environmentObject(authViewModel)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Prescriptions Tab

    private var prescriptionsContent: some View {
        Group {
            if authViewModel.patientPrescriptions.isEmpty {
                MedicalEmptyState(
                    title: "No prescriptions yet",
                    subtitle: "Add your historical prescriptions or they'll appear here after a doctor adds them.",
                    icon: "cross.case.fill",
                    color: .blue
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(authViewModel.patientPrescriptions) { prescription in
                        PrescriptionCard(
                            prescription: prescription,
                            isExpanded: expandedRecordId == prescription.id
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedRecordId = (expandedRecordId == prescription.id) ? nil : prescription.id
                            }
                        } onDelete: {
                            authViewModel.deletePatientPrescription(prescription)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Blood Tests Tab

    private var bloodTestsContent: some View {
        Group {
            if authViewModel.patientBloodTests.isEmpty {
                MedicalEmptyState(
                    title: "No blood tests yet",
                    subtitle: "Tap '+' to add your blood test results and keep them in one place.",
                    icon: "drop.fill",
                    color: .red
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(authViewModel.patientBloodTests) { test in
                        BloodTestCard(
                            record: test,
                            isExpanded: expandedRecordId == test.id
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedRecordId = (expandedRecordId == test.id) ? nil : test.id
                            }
                        } onDelete: {
                            authViewModel.deleteBloodTest(test)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Prescription Card

private struct PrescriptionCard: View {
    let prescription: PatientPrescription
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: prescription.isFromDoctor ? "stethoscope" : "cross.case.fill")
                        .font(.headline)
                        .foregroundColor(prescription.isFromDoctor ? .indigo : .blue)
                        .frame(width: 36, height: 36)
                        .background((prescription.isFromDoctor ? Color.indigo : Color.blue).opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(prescription.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        if prescription.isFromDoctor, let doctorName = prescription.doctorName {
                            Label(doctorName, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundColor(.indigo)
                        } else {
                            Text("Added by you")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(prescription.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                Text(prescription.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Only patient-added prescriptions can be deleted by the patient
                if !prescription.isFromDoctor {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Record", systemImage: "trash")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(prescription.isFromDoctor ? Color.indigo.opacity(0.25) : Color.blue.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Blood Test Card

private struct BloodTestCard: View {
    let record: BloodTestRecord
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.testName)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text("Blood Test Result")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                Text(record.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button(role: .destructive, action: onDelete) {
                    Label("Delete Record", systemImage: "trash")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.red.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Empty State

private struct MedicalEmptyState: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color.opacity(0.6))

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Add Prescription Sheet

struct AddPrescriptionSheet: View {
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
                Section(header: Text("Prescription Details")) {
                    TextField("Title  (e.g., Dr. Rafi – Feb 2025)", text: $title)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prescription Content")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $content)
                            .frame(minHeight: 160)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Text("You can paste or type the full prescription text here, including medications, dosage, and doctor instructions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save").fontWeight(.bold)
                        }
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
        isSaving = true
        authViewModel.addPatientPrescription(title: title, content: content) { success in
            isSaving = false
            if success { dismiss() } else { showError = true }
        }
    }
}

// MARK: - Add Blood Test Sheet

struct AddBloodTestSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var testName = ""
    @State private var content = ""
    @State private var isSaving = false
    @State private var showError = false

    var isValid: Bool {
        !testName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Test Information")) {
                    TextField("Test Name  (e.g., CBC, Lipid Panel)", text: $testName)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Test Results")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $content)
                            .frame(minHeight: 160)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Text("Enter your test results or paste the lab report text here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Blood Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save").fontWeight(.bold)
                        }
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
        isSaving = true
        authViewModel.addBloodTest(testName: testName, content: content) { success in
            isSaving = false
            if success { dismiss() } else { showError = true }
        }
    }
}
