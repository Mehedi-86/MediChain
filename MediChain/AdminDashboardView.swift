import SwiftUI

private enum AdminPanel: String, CaseIterable, Identifiable {
    case doctors = "Doctors"
    case patients = "Patients"
    case breakingNews = "Breaking Info"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .doctors:
            return "stethoscope"
        case .patients:
            return "person.3"
        case .breakingNews:
            return "newspaper"
        }
    }
}

struct AdminDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedPanel: AdminPanel? = .doctors
    @State private var splitVisibility: NavigationSplitViewVisibility = .all
    @State private var presentedPanel: AdminPanel?
    @State private var selectedUserForDeletion: MediUser?
    @State private var doctorSearchText = ""
    @State private var patientSearchText = ""

    @State private var newsTitle = ""
    @State private var newsBrief = ""
    @State private var newsArticle = ""
    @State private var newsStatusMessage = ""

    private var filteredDoctors: [MediUser] {
        let query = doctorSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return authViewModel.adminDoctors }

        return authViewModel.adminDoctors.filter { doctor in
            let name = (doctor.fullName ?? "").lowercased()
            let specialty = (doctor.specialty ?? "").lowercased()
            let region = (doctor.region ?? "").lowercased()
            let email = doctor.email.lowercased()
            return name.contains(query) || specialty.contains(query) || region.contains(query) || email.contains(query)
        }
    }

    private var filteredPatients: [MediUser] {
        let query = patientSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return authViewModel.adminPatients }

        return authViewModel.adminPatients.filter { patient in
            let name = (patient.fullName ?? "").lowercased()
            let email = patient.email.lowercased()
            let doctorNames = Array(Set(
                authViewModel.adminAppointments
                    .filter { $0.patientId == patient.uid }
                    .compactMap { $0.doctorName?.lowercased() }
            ))
            return name.contains(query) || email.contains(query) || doctorNames.contains(where: { $0.contains(query) })
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $splitVisibility) {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.07, green: 0.24, blue: 0.33), Color(red: 0.05, green: 0.13, blue: 0.23)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Admin Console")
                            .font(.title3)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        Text("Manage users and public alerts")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.78))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0.24), Color.white.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.top, 8)

                    ForEach(AdminPanel.allCases) { panel in
                        let isActive = selectedPanel == panel

                        Button {
                            selectedPanel = panel
                            if horizontalSizeClass == .compact {
                                presentedPanel = panel
                            } else {
                                splitVisibility = .detailOnly
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: panel.icon)
                                    .font(.headline)
                                    .foregroundColor(isActive ? .teal : .white.opacity(0.85))
                                    .frame(width: 32, height: 32)
                                    .background(isActive ? Color.teal.opacity(0.16) : Color.white.opacity(0.09))
                                    .clipShape(Circle())

                                Text(panel.rawValue)
                                    .fontWeight(.semibold)
                                    .foregroundColor(isActive ? Color.white : Color.white.opacity(0.82))

                                Spacer()

                                if isActive {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.teal)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(
                                Group {
                                    if isActive {
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.28), Color.white.opacity(0.16)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        Color.white.opacity(0.06)
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(isActive ? Color.teal.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 0)

                    Divider()
                        .overlay(Color.white.opacity(0.25))

                    Button(role: .destructive) {
                        authViewModel.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.80, blue: 0.78))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .background(Color.red.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(Color.red.opacity(0.30), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }
            .navigationTitle("Admin")
        } detail: {
            ZStack {
                LinearGradient(
                    colors: [Color(UIColor.systemGroupedBackground), Color(UIColor.secondarySystemGroupedBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Group {
                    detailContent(for: selectedPanel ?? .doctors)
                }
            }
            .padding()
            .toolbar {
                if horizontalSizeClass == .compact {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            splitVisibility = .all
                        } label: {
                            Label("Menu", systemImage: "sidebar.left")
                        }
                    }
                }
            }
        }
        .onAppear {
            authViewModel.fetchAdminDoctors()
            authViewModel.fetchAdminPatients()
            authViewModel.fetchAdminAppointments()
            authViewModel.fetchBreakingNews()
        }
        .alert("Delete User", isPresented: Binding(
            get: { selectedUserForDeletion != nil },
            set: { if !$0 { selectedUserForDeletion = nil } }
        )) {
            Button("Delete", role: .destructive) {
                guard let selectedUserForDeletion else { return }
                authViewModel.deleteUserRegistration(user: selectedUserForDeletion)
                self.selectedUserForDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                selectedUserForDeletion = nil
            }
        } message: {
            if let selectedUserForDeletion {
                Text("Are you sure you want to remove \(selectedUserForDeletion.fullName ?? selectedUserForDeletion.email)?")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Sign Out") {
                    authViewModel.signOut()
                }
                .foregroundColor(.red)
            }
        }
        .sheet(item: $presentedPanel) { panel in
            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [Color(UIColor.systemGroupedBackground), Color(UIColor.secondarySystemGroupedBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    detailContent(for: panel)
                        .padding()
                }
                .navigationTitle(panel.rawValue)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            presentedPanel = nil
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sign Out") {
                            authViewModel.signOut()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func detailContent(for panel: AdminPanel) -> some View {
        switch panel {
        case .doctors:
            doctorsSection
        case .patients:
            patientsSection
        case .breakingNews:
            breakingNewsSection
        }
    }

    private var doctorsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AdminSectionHeader(
                    title: "Registered Doctors",
                    subtitle: "Monitor non-sensitive doctor profile data",
                    icon: "stethoscope",
                    count: filteredDoctors.count
                )

                AdminSearchBar(
                    placeholder: "Search by name, specialty, region, or email",
                    text: $doctorSearchText
                )

                if filteredDoctors.isEmpty {
                    AdminEmptyState(
                        title: "No doctors found",
                        subtitle: "Try another keyword or clear search.",
                        icon: "person.crop.circle.badge.questionmark"
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredDoctors, id: \.uid) { doctor in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doctor.fullName ?? "Unnamed Doctor")
                                            .font(.headline)
                                        Text(doctor.specialty ?? "Specialty not set")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()

                                    Button(role: .destructive) {
                                        selectedUserForDeletion = doctor
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                }

                                HStack(spacing: 8) {
                                    InfoChip(icon: "mappin.and.ellipse", text: doctor.region?.isEmpty == false ? doctor.region! : "Region not set")
                                    InfoChip(icon: "clock", text: "\(doctor.dutyStart ?? "-") - \(doctor.dutyEnd ?? "-")")
                                }

                                InfoChip(icon: "person.2.badge.gearshape", text: "Daily limit: \(doctor.dailyLimit ?? 0)")
                            }
                            .adminCardStyle()
                        }
                    }
                }
            }
        }
    }

    private var patientsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AdminSectionHeader(
                    title: "Registered Patients",
                    subtitle: "Review booking connections with doctors",
                    icon: "person.3",
                    count: filteredPatients.count
                )

                AdminSearchBar(
                    placeholder: "Search by name, email, or booked doctor",
                    text: $patientSearchText
                )

                if filteredPatients.isEmpty {
                    AdminEmptyState(
                        title: "No patients found",
                        subtitle: "Try another keyword or clear search.",
                        icon: "person.crop.circle.badge.exclamationmark"
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPatients, id: \.uid) { patient in
                            let appointments = authViewModel.adminAppointments.filter { $0.patientId == patient.uid }
                            let uniqueDoctors = Array(Set(appointments.compactMap { $0.doctorName })).sorted()

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(patient.fullName ?? "Unnamed Patient")
                                            .font(.headline)
                                        Text("Appointments: \(appointments.count)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()

                                    Button(role: .destructive) {
                                        selectedUserForDeletion = patient
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                }

                                if uniqueDoctors.isEmpty {
                                    InfoChip(icon: "stethoscope", text: "Booked with: No doctor yet")
                                } else {
                                    InfoChip(icon: "stethoscope", text: "Booked with: \(uniqueDoctors.joined(separator: ", "))")
                                }
                            }
                            .adminCardStyle()
                        }
                    }
                }
            }
        }
    }

    private var breakingNewsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AdminSectionHeader(
                    title: "Breaking Information",
                    subtitle: "Publish public alerts shown from login page",
                    icon: "newspaper",
                    count: authViewModel.breakingNews.count
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Create Update")
                        .font(.headline)

                    TextField("Title", text: $newsTitle)
                        .textFieldStyle(.roundedBorder)

                    TextField("Short Brief (1-2 lines)", text: $newsBrief)
                        .textFieldStyle(.roundedBorder)

                    TextEditor(text: $newsArticle)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )

                    Text("Formatting: # Heading, ## Subheading, - Bullet point, normal line = paragraph. If Shift+3 gives £ on your keyboard, you can also use £ / ££ for headings.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        authViewModel.addBreakingNews(title: newsTitle, brief: newsBrief, article: newsArticle) { success in
                            if success {
                                newsStatusMessage = "Published successfully."
                                newsTitle = ""
                                newsBrief = ""
                                newsArticle = ""
                            } else {
                                newsStatusMessage = "Publish failed. Fill title, brief, and article."
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "megaphone.fill")
                            Text("Publish Update")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .adminCardStyle()

                if !newsStatusMessage.isEmpty {
                    Text(newsStatusMessage)
                        .font(.footnote)
                        .foregroundColor(.teal)
                }

                Text("Latest Updates")
                    .font(.headline)

                if authViewModel.breakingNews.isEmpty {
                    AdminEmptyState(
                        title: "No updates posted yet",
                        subtitle: "Published updates will appear here.",
                        icon: "newspaper"
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(authViewModel.breakingNews) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    Text(item.title)
                                        .font(.headline)
                                    Spacer()
                                    Button(role: .destructive) {
                                        authViewModel.deleteBreakingNews(item: item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                }

                                Text(item.displayBrief)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                InfoChip(
                                    icon: "calendar.badge.clock",
                                    text: item.createdAt.formatted(date: .abbreviated, time: .shortened)
                                )
                            }
                            .adminCardStyle()
                        }
                    }
                }
            }
        }
    }
}

private struct AdminSectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.teal)
                .frame(width: 42, height: 42)
                .background(Color.teal.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.teal.opacity(0.14))
                .foregroundColor(.teal)
                .clipShape(Capsule())
        }
        .adminCardStyle()
    }
}

private struct AdminSearchBar: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .lineLimit(2)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(Capsule())
    }
}

private struct AdminEmptyState: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .adminCardStyle()
    }
}

private extension View {
    func adminCardStyle() -> some View {
        self
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}
