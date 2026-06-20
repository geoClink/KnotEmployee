import SwiftUI

struct TimeOffView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @State private var showNewRequest = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                balancePills

                if store.timeOff.isEmpty {
                    emptyState
                } else {
                    section("Requests") {
                        VStack(spacing: 10) {
                            ForEach(store.timeOff) { request in
                                TimeOffRequestRow(request: request)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        if request.status == .pending {
                                            Button(role: .destructive) {
                                                Task { await store.cancelTimeOff(id: request.id) }
                                            } label: {
                                                Label("Cancel", systemImage: "xmark")
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .refreshable { try? await store.loadInitialData() }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Time off")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewRequest = true } label: {
                    IconView(icon: .plus, size: 22, color: theme.rose)
                }
                .accessibilityLabel("New time off request")
            }
        }
        .sheet(isPresented: $showNewRequest) {
            NewTimeOffView()
        }
    }

    private var sickDaysUsed: Int {
        store.timeOff.filter { $0.kind == .sick && $0.status == .approved }.reduce(0) { $0 + $1.days }
    }
    private var personalDaysUsed: Int {
        store.timeOff.filter { $0.kind == .personal && $0.status == .approved }.reduce(0) { $0 + $1.days }
    }

    private var balancePills: some View {
        let pto = store.currentUser.ptoDaysRemaining
        return HStack(spacing: 8) {
            balancePill("PTO", pto == 1 ? "1 day" : "\(Int(pto)) days")
            balancePill("Sick", sickDaysUsed == 0 ? "None used" : "\(sickDaysUsed) days")
            balancePill("Personal", personalDaysUsed == 0 ? "None used" : "\(personalDaysUsed) days")
        }
    }

    private func balancePill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
            Text(label).font(theme.body(11)).foregroundStyle(theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(theme.display(18)).foregroundStyle(theme.ink)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            IconView(icon: .calendar, size: 28, color: theme.inkFaint)
                .frame(width: 64, height: 64)
                .background(theme.creamDeep, in: Circle())
                .accessibilityHidden(true)
            Text("No time off requests").font(theme.display(21)).foregroundStyle(theme.ink)
            Text("Tap + to submit a new request for PTO, sick leave, or personal time.")
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

#Preview {
    TimeOffView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
