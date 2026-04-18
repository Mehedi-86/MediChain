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
    @State private var isExpanded = false
    @State private var showFullDetails = false

    private var purposeFull: String? {
        normalizedText(from: drugDetails.purpose?.first)
    }

    private var dosageFull: String? {
        normalizedText(from: drugDetails.dosageAndAdministration?.first)
    }

    private var warningFull: String? {
        normalizedText(from: drugDetails.warnings?.first)
    }

    private var purposeBullet: String? {
        conciseBullet(from: purposeFull)
    }

    private var dosageBullet: String? {
        conciseBullet(from: dosageFull)
    }

    private var warningBullet: String? {
        conciseBullet(from: warningFull)
    }

    private var summaryBullets: [(String, String, Color)] {
        var bullets: [(String, String, Color)] = []

        if let purposeBullet {
            bullets.append(("Purpose", purposeBullet, .blue))
        }

        if let dosageBullet {
            bullets.append(("How to take", dosageBullet, .teal))
        }

        if let warningBullet {
            bullets.append(("Warning", warningBullet, .red))
        }

        if bullets.isEmpty {
            bullets.append(("Info", "No concise FDA summary available for this medicine.", .gray))
        }

        return bullets
    }

    private var fullSections: [(String, String, Color)] {
        var sections: [(String, String, Color)] = []

        if let purposeFull {
            sections.append(("Purpose", purposeFull, .blue))
        }

        if let dosageFull {
            sections.append(("How to take", dosageFull, .teal))
        }

        if let warningFull {
            sections.append(("Warning", warningFull, .red))
        }

        if sections.isEmpty {
            sections.append(("Info", "No detailed FDA information available for this medicine.", .gray))
        }

        return sections
    }

    private func normalizedText(from text: String?) -> String? {
        guard let text else { return nil }

        let cleaned = text
            .replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }
        return cleaned
    }

    private func conciseBullet(from text: String?) -> String? {
        guard let cleaned = text, !cleaned.isEmpty else { return nil }

        let firstSentence = cleaned
            .components(separatedBy: ".")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? cleaned

        let target = firstSentence.count > 220 ? firstSentence : cleaned

        if target.count <= 220 {
            return target
        }

        let limit = target.index(target.startIndex, offsetBy: 220)
        let chunk = String(target[..<limit])
        if let lastSpace = chunk.lastIndex(of: " ") {
            return String(chunk[..<lastSpace]) + "..."
        }

        return chunk + "..."
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(medicineName.capitalized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(isExpanded ? "Tap to hide details" : "Tap to see details")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showFullDetails.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showFullDetails ? "text.justify" : "list.bullet")
                            Text(showFullDetails ? "Show Brief" : "Show Full")
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    ForEach(Array((showFullDetails ? fullSections : summaryBullets).enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(bullet.2)
                                .frame(width: 7, height: 7)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(bullet.0)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(bullet.2)
                                Text(bullet.1)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    Text("For full medical decision-making, consult a doctor.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
