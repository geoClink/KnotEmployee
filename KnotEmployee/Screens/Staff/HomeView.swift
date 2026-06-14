import SwiftUI

struct HomeView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Good morning, \(firstName)")
                        .font(theme.display(30)).foregroundStyle(theme.ink)

                    ForEach(store.shift) { shift in
                        NavigationLink {
                            ShiftDetailView(shift: shift, onGiveUp: { giveUp(shift) })
                        } label: {
                            ShiftCard(shift: shift)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(theme.cream.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { OpenShiftsView() } label: {
                        IconView(icon: .handoff, size: 22, color: theme.rose)
                    }
                }
            }
        }
    }

    private var firstName: String {
        store.currentUser.name.split(separator: " ").first.map(String.init) ?? ""
    }

    private func giveUp(_ shift: Shift) {
        store.openShifts.append(
            OpenShift(offeredBy: "You", day: shift.day, date: shift.date,
                      start: shift.start, end: shift.end, role: shift.role, status: .offered)
        )
    }
}

#Preview {
    HomeView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
