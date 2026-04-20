import SwiftUI

struct BreakingNewsFeedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    private let alertThemes: [AlertTheme] = [
        AlertTheme(primary: Color(red: 0.11, green: 0.56, blue: 0.80), secondary: Color(red: 0.52, green: 0.82, blue: 0.94), icon: "drop.triangle"),
        AlertTheme(primary: Color(red: 0.62, green: 0.25, blue: 0.76), secondary: Color(red: 0.83, green: 0.58, blue: 0.95), icon: "waveform.path.ecg"),
        AlertTheme(primary: Color(red: 0.85, green: 0.37, blue: 0.15), secondary: Color(red: 0.98, green: 0.67, blue: 0.42), icon: "cross.vial"),
        AlertTheme(primary: Color(red: 0.09, green: 0.58, blue: 0.46), secondary: Color(red: 0.57, green: 0.86, blue: 0.72), icon: "leaf"),
        AlertTheme(primary: Color(red: 0.78, green: 0.22, blue: 0.24), secondary: Color(red: 0.95, green: 0.58, blue: 0.59), icon: "exclamationmark.triangle")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(UIColor.systemGroupedBackground), Color.cyan.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(
                                colors: [Color(red: 0.05, green: 0.38, blue: 0.57), Color(red: 0.08, green: 0.24, blue: 0.39)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            Circle()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: 180, height: 180)
                                .offset(x: 120, y: -60)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    Image(systemName: "megaphone.fill")
                                        .foregroundColor(.white)
                                    Text("Latest Public Health Alerts")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(authViewModel.breakingNews.count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.2))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }

                                Text("Stay aware of disease outbreaks and urgent public health notices.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.88))
                                    .lineLimit(2)
                            }
                            .padding(16)
                        }
                        .frame(minHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)

                        if authViewModel.breakingNews.isEmpty {
                            VStack(alignment: .center, spacing: 12) {
                                Image(systemName: "newspaper")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No breaking updates yet")
                                    .font(.headline)
                                Text("When admin publishes important updates, they will show up here.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 14)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(authViewModel.breakingNews.enumerated()), id: \.offset) { index, item in
                                    let theme = alertThemes[index % alertThemes.count]

                                    NavigationLink {
                                        BreakingNewsArticleView(item: item, theme: theme)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack(alignment: .top, spacing: 10) {
                                                Image(systemName: theme.icon)
                                                    .font(.headline)
                                                    .foregroundColor(theme.primary)
                                                    .frame(width: 32, height: 32)
                                                    .background(theme.primary.opacity(0.14))
                                                    .clipShape(Circle())

                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text(item.title)
                                                        .font(.headline)
                                                        .foregroundColor(.primary)

                                                    Text(item.displayBrief)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(3)
                                                }

                                                Spacer()

                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(theme.primary)
                                            }

                                            HStack(spacing: 6) {
                                                Image(systemName: "calendar.badge.clock")
                                                    .font(.caption)
                                                    .foregroundColor(theme.primary)
                                                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                        .background(
                                            LinearGradient(
                                                colors: [theme.secondary.opacity(0.18), Color(UIColor.secondarySystemGroupedBackground)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(theme.primary.opacity(0.24), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Breaking Information")
            .onAppear {
                authViewModel.fetchBreakingNews()
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct AlertTheme {
    let primary: Color
    let secondary: Color
    let icon: String
}

private struct BreakingNewsArticleView: View {
    let item: BreakingNewsItem
    let theme: AlertTheme

    private var blocks: [ArticleBlock] {
        item.displayArticle
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { originalLine in
                let line: String = {
                    if originalLine.hasPrefix("££ ") {
                        return "## " + String(originalLine.dropFirst(3))
                    }
                    if originalLine.hasPrefix("£ ") {
                        return "# " + String(originalLine.dropFirst(2))
                    }
                    return originalLine
                }()

                if line.hasPrefix("## ") {
                    return .subheading(String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces))
                }

                if line.hasPrefix("# ") {
                    return .heading(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                }

                if line.hasPrefix("- ") || line.hasPrefix("* ") {
                    return .bullet(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                }

                return .paragraph(line)
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(item.displayBrief)
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                        Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption)
                    .foregroundColor(theme.primary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.secondary.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.primary.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        switch block {
                        case .heading(let text):
                            Text(text)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(theme.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(theme.secondary.opacity(0.14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.primary.opacity(0.25), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        case .subheading(let text):
                            Text(text)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(UIColor.tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        case .bullet(let text):
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(theme.primary)
                                    .frame(width: 7, height: 7)
                                    .padding(.top, 7)

                                Text(text)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        case .paragraph(let text):
                            Text(text)
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Full Article")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}

private enum ArticleBlock {
    case heading(String)
    case subheading(String)
    case bullet(String)
    case paragraph(String)
}
