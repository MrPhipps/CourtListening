import SwiftUI
import CourtListeningCore

/// Full-text docket search. Submitting the search bar issues a `DocketQuery`; results are
/// read from the observed store snapshot and navigate into `DocketDetailView`.
struct DocketSearchView: View {
    @Bindable var store: CourtListenerStore
    @State private var query: String = ""

    private var dockets: [Docket] {
        store.model.dockets.values.sorted { $0.dateModified > $1.dateModified }
    }

    var body: some View {
        NavigationStack {
            List {
                if let error = store.model.lastError {
                    ErrorBanner(message: error.errorDescription ?? "Something went wrong")
                }
                ForEach(dockets, id: \.id) { docket in
                    NavigationLink(value: docket.id) { DocketRow(docket: docket) }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Dockets")
            .navigationDestination(for: DocketID.self) { id in
                if let docket = store.model.dockets[id] {
                    DocketDetailView(docket: docket, store: store)
                }
            }
            .searchable(text: $query, prompt: "Search dockets")
            .onSubmit(of: .search, runSearch)
            .overlay { if dockets.isEmpty { emptyState } }
        }
    }

    private func runSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let term = try? NonEmptyString(trimmed) else { return }
        store.searchDockets(DocketQuery(searchTerm: term))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Search dockets",
            systemImage: "magnifyingglass",
            description: Text("Enter a case name or keyword and press return.")
        )
    }
}

struct DocketRow: View {
    let docket: Docket

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            Text(docket.caseName).font(Design.Font.heading).lineLimit(2)
            HStack(spacing: Design.Spacing.sm) {
                if !docket.docketNumber.isEmpty {
                    Text(docket.docketNumber).font(Design.Font.caption).foregroundStyle(Design.Color.secondaryText)
                }
                Text(docket.courtID.rawValue).font(Design.Font.caption).foregroundStyle(Design.Color.accent)
            }
        }
        .padding(.vertical, Design.Spacing.xs)
    }
}

#if DEBUG
#Preview("Docket Row") {
    List { DocketRow(docket: .TestData.sampleDocket) }
}

#Preview("Docket Search") {
    DocketSearchView(store: .preview({
        var m = CourtListenerModel.initial
        m.dockets[Docket.TestData.sampleDocket.id] = .TestData.sampleDocket
        return m
    }()))
}
#endif
