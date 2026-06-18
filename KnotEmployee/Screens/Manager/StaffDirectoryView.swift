import SwiftUI

struct StaffDirectoryView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var showAddEmployee = false

    private var filtered: [StaffMember] {
        query.isEmpty ? store.staff
                      : store.staff.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    private var onClock: Int { store.staff.filter { $0.clockStatus != .out }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(store.staff.count) staff · \(onClock) on the clock")
                        .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                        .padding(.bottom, 12)

                    HStack(spacing: 10) {
                        IconView(icon: .search, size: 18, color: theme.inkFaint)
                        TextField("Search staff", text: $query)
                            .font(theme.body(15)).foregroundStyle(theme.ink)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 11)
                    .background(theme.card, in: Capsule())
                    .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
                    .padding(.bottom, 8)

                    ForEach(filtered) { person in
                        NavigationLink {
                            StaffDetailView(person: person)
                        } label: {
                            StaffRow(person: person)
                        }
                        .buttonStyle(.plain)
                        if person.id != filtered.last?.id {
                            Rectangle().fill(theme.lineSoft).frame(height: 1).padding(.leading, 60)
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Team")
            .task { await store.refreshClockStatuses() }
            .refreshable { await store.refreshClockStatuses() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddEmployee = true } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 17))
                            .foregroundStyle(theme.ink)
                    }
                    .accessibilityLabel("Add employee")
                }
            }
            .sheet(isPresented: $showAddEmployee) {
                AddEmployeeView()
            }
        }
    }
}

#Preview {
    StaffDirectoryView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
