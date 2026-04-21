// AppointmentDetailView.swift
// MediChain

import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var linkedPrescription: PatientPrescription? = nil
    @State private var isLoadingPrescription = false
    @State private var prescriptionLoaded = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: - Appointment Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "stethoscope.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(appointment.doctorName ?? "Doctor")
                                    .font(.title3)
                                    .fontWeight(.bold)

                                Text("Appointment Details")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let serial = appointment.serialNumber {
                                Text("#\(serial)")
                                    .font(.caption)
                                    .fontWeight(.heavy)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.18))
                                    .foregroundColor(.orange)
                                    .clipShape(Capsule())
                            }
                        }

                        Divider()

                        DetailInfoRow(icon: "calendar", label: "Date",
                                      value: appointment.date.formatted(.dateTime.day().month().year()))
                        DetailInfoRow(icon: "clock", label: "Time Slot",
                                      value: appointment.timeSlot ?? "Not specified")
                        DetailInfoRow(icon: "waveform.path.ecg", label: "Status",
                                      value: appointment.status)

                        if !appointment.notes.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Your Notes", systemImage: "doc.text")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                Text(appointment.notes)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

                    // MARK: - Doctor's Prescription Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "cross.case.fill")
                                .font(.headline)
                                .foregroundColor(.indigo)
                                .frame(width: 36, height: 36)
                                .background(Color.indigo.opacity(0.12))
                                .clipShape(Circle())

                            Text("Doctor's Prescription")
                                .font(.headline)

                            Spacer()
                        }

                        Divider()

                        if isLoadingPrescription {
                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    ProgressView()
                                    Text("Loading prescription...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 24)

                        } else if let prescription = linkedPrescription {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(prescription.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        if let doctorName = prescription.doctorName {
                                            Label(doctorName, systemImage: "person.fill")
                                                .font(.caption)
                                                .foregroundColor(.indigo)
                                        }

                                        Text(prescription.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                Text(prescription.content)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                        } else if prescriptionLoaded {
                            VStack(spacing: 10) {
                                Image(systemName: "cross.case")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text("No prescription added yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("Your doctor hasn't written a prescription for this appointment yet.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadLinkedPrescription() }
        }
        .navigationViewStyle(.stack)
    }

    private func loadLinkedPrescription() {
        if let prescriptionId = appointment.prescriptionId, !prescriptionId.isEmpty {
            isLoadingPrescription = true
            authViewModel.fetchPrescriptionById(prescriptionId) { prescription in
                self.linkedPrescription = prescription
                self.isLoadingPrescription = false
                self.prescriptionLoaded = true
            }
        } else {
            prescriptionLoaded = true
        }
    }
}

private struct DetailInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}
