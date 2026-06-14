import SwiftUI

struct HomeView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    private let order = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
    private let today = "Thu"

    private var todayShift: Shift? { store.shift.first { $0.day == today } }
    private var upcoming: [Shift] {
        let ti = order.firstIndex(of: today) ?? 0
        return store.shift.filter { (order.firstIndex(of: $0.day) ?? 0) > ti }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    greeting
                    ClockStatusBanner()

                    if let todayShift {
                        section("Today’s shift") {
                            shiftLink(todayShift)
                        }
                    }
                    if !upcoming.isEmpty {
                        section("Upcoming") {
                            VStack(spacing: 10) { ForEach(upcoming) { shiftLink($0) } }
                        }
                    }
                }
                .padding(20)
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

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Thursday, June 12").font(theme.body(13)).foregroundStyle(theme.inkMuted)
            Text("Good morning, \(firstName)").font(theme.display(30)).foregroundStyle(theme.ink)
        }
    }

    private func shiftLink(_ shift: Shift) -> some View {
        NavigationLink {
            ShiftDetailView(shift: shift, onGiveUp: { giveUp(shift) })
        } label: {
            ShiftCard(shift: shift)
        }
        .buttonStyle(.plain)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(theme.display(18)).foregroundStyle(theme.ink)
            content()
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
