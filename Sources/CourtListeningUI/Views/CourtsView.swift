import SwiftUI
import CourtListeningCore

/// Paginated courts browser. Observes the store snapshot and drives page-based pagination
/// (courts use `?page=N`). Sign-out is surfaced here as the primary toolbar action.
struct CourtsView: View {
    @Bindable var store: CourtListenerStore
    let onSignOut: () -> Void

    private var sortedCourts: [Court] {
        store.model.courts.values.sorted { $0.position < $1.position }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedCourts, id: \.id) { court in
                    NavigationLink(value: court.id) { CourtRow(court: court) }
                }
                if let error = store.model.lastError {
                    ErrorBanner(message: error.errorDescription ?? "Something went wrong")
                }
                if store.model.courtsPagination.hasMore {
                    loadMoreRow
                }
            }
            .listStyle(.plain)
            .navigationTitle("Courts")
            .navigationDestination(for: CourtID.self) { id in
                if let court = store.model.courts[id] {
                    CourtDetailView(court: court)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Sign Out", role: .destructive, action: onSignOut)
                }
            }
            .overlay { if sortedCourts.isEmpty { emptyState } }
            .task { if store.model.courts.isEmpty { store.loadCourts() } }
        }
    }

    private var loadMoreRow: some View {
        HStack {
            Spacer()
            Button("Load more") { store.loadNextCourtsPage() }
                .buttonStyle(.bordered)
            Spacer()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView("No courts yet", systemImage: "building.columns", description: Text("Pull from the API to load courts."))
    }
}

/// A single row in the courts list.
struct CourtRow: View {
    let court: Court

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            Text(court.shortName).font(Design.Font.heading)
            HStack(spacing: Design.Spacing.sm) {
                Text(court.citationString).font(Design.Font.caption).foregroundStyle(Design.Color.secondaryText)
                Text(court.jurisdiction.displayName).font(Design.Font.caption).foregroundStyle(Design.Color.accent)
            }
        }
        .padding(.vertical, Design.Spacing.xs)
    }
}

/// Read-only detail for a single court.
struct CourtDetailView: View {
    let court: Court

    var body: some View {
        List {
            Section("Identity") {
                labeled("Full name", court.fullName)
                labeled("Short name", court.shortName)
                labeled("Citation", court.citationString)
                labeled("Jurisdiction", court.jurisdiction.displayName)
            }
            Section("Status") {
                labeled("In use", court.inUse ? "Yes" : "No")
                labeled("Founded", court.startDate ?? "—")
                if let end = court.endDate { labeled("Ended", end) }
            }
            if let url = court.websiteURL {
                Section("Website") {
                    Link(url.absoluteString, destination: url).font(Design.Font.body)
                }
            }
        }
        .navigationTitle(court.shortName)
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(Design.Font.caption).foregroundStyle(Design.Color.secondaryText)
            Spacer(minLength: Design.Spacing.md)
            Text(value).font(Design.Font.body).multilineTextAlignment(.trailing)
        }
    }
}

#if DEBUG
#Preview("Court Row") {
    List {
        CourtRow(court: .TestData.supremeCourt)
        CourtRow(court: .TestData.firstCircuit)
    }
}

#Preview("Court Detail") {
    NavigationStack { CourtDetailView(court: .TestData.supremeCourt) }
}

#Preview("Courts List") {
    CourtsView(store: .preview(.TestVariants.withSCOTUS), onSignOut: {})
}
#endif
