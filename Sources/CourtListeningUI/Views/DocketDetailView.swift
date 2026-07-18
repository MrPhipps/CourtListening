import SwiftUI
import CourtListeningCore

/// Docket detail. On appear it fans out three fetches — oral arguments, parties, attorneys —
/// each stored under the docket ID and rendered from the observed snapshot.
struct DocketDetailView: View {
    let docket: Docket
    @Bindable var store: CourtListenerStore

    private var recordings: [Audio] { store.model.oralArguments[docket.id] ?? [] }
    private var parties: [Party] { store.model.parties[docket.id] ?? [] }
    private var attorneys: [Attorney] { store.model.attorneys[docket.id] ?? [] }

    var body: some View {
        List {
            Section("Case") {
                labeled("Case name", docket.caseName)
                if !docket.docketNumber.isEmpty { labeled("Docket №", docket.docketNumber) }
                labeled("Court", docket.courtID.rawValue)
                if let filed = docket.dateFiled { labeled("Filed", filed) }
                if !docket.natureOfSuit.isEmpty { labeled("Nature of suit", docket.natureOfSuit) }
                if !docket.assignedToStr.isEmpty { labeled("Assigned to", docket.assignedToStr) }
            }

            Section("Oral Arguments") {
                if recordings.isEmpty {
                    placeholder("No recordings")
                } else {
                    ForEach(recordings, id: \.id) { AudioRow(audio: $0) }
                }
            }

            Section("Parties") {
                if parties.isEmpty {
                    placeholder("No parties")
                } else {
                    ForEach(parties, id: \.id) { party in
                        Text(party.name).font(Design.Font.body)
                    }
                }
            }

            Section("Attorneys") {
                if attorneys.isEmpty {
                    placeholder("No attorneys")
                } else {
                    ForEach(attorneys, id: \.id) { AttorneyRow(attorney: $0) }
                }
            }
        }
        .navigationTitle(docket.caseNameShort.isEmpty ? "Docket" : docket.caseNameShort)
        .task {
            store.loadOralArguments(docketID: docket.id)
            store.loadParties(docketID: docket.id)
            store.loadAttorneys(docketID: docket.id)
        }
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(Design.Font.caption).foregroundStyle(Design.Color.secondaryText)
            Spacer(minLength: Design.Spacing.md)
            Text(value).font(Design.Font.body).multilineTextAlignment(.trailing)
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text).font(Design.Font.caption).foregroundStyle(Design.Color.secondaryText)
    }
}

/// A single oral-argument recording with a play/open link.
struct AudioRow: View {
    let audio: Audio

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            Text(audio.caseName).font(Design.Font.body).lineLimit(2)
            HStack(spacing: Design.Spacing.md) {
                Label(Self.durationLabel(audio.duration), systemImage: "clock")
                    .font(Design.Font.caption)
                    .foregroundStyle(Design.Color.secondaryText)
                if let url = audio.downloadURL {
                    Link(destination: url) {
                        Label("Play", systemImage: "play.circle.fill")
                    }
                    .font(Design.Font.caption)
                }
            }
        }
        .padding(.vertical, Design.Spacing.xs)
    }

    /// Whole seconds → "m:ss".
    static func durationLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }
}

struct AttorneyRow: View {
    let attorney: Attorney

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            Text(attorney.name).font(Design.Font.body)
            if let phone = attorney.phone {
                Text(phone.rawValue).font(Design.Font.caption).foregroundStyle(Design.Color.secondaryText)
            }
            if let email = attorney.email {
                Text(email.rawValue).font(Design.Font.caption).foregroundStyle(Design.Color.secondaryText)
            }
        }
        .padding(.vertical, Design.Spacing.xs)
    }
}

#if DEBUG
#Preview("Audio Row") {
    List { AudioRow(audio: .TestData.inReCatron) }
}

#Preview("Docket Detail") {
    NavigationStack {
        DocketDetailView(
            docket: .TestData.sampleDocket,
            store: .preview({
                var m = CourtListenerModel.initial
                let id = Docket.TestData.sampleDocket.id
                m.dockets[id] = .TestData.sampleDocket
                m.parties[id] = [.TestData.petitioner]
                m.attorneys[id] = [.TestData.sampleAttorney]
                m.oralArguments[id] = [.TestData.inReCatron]
                return m
            }())
        )
    }
}
#endif
