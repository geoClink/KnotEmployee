import SwiftUI

struct NotificationsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    private var todayNotifs: [AppNotification] {
        store.notifications.filter { Calendar.current.isDateInToday($0.createdAt) }
    }
    private var earlierNotifs: [AppNotification] {
        store.notifications.filter { !Calendar.current.isDateInToday($0.createdAt) }
    }

    var body: some View {
        ScrollView {
            if store.notifications.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if !todayNotifs.isEmpty {
                        section("Today") {
                            notifGroup(todayNotifs)
                        }
                    }
                    if !earlierNotifs.isEmpty {
                        section("Earlier") {
                            notifGroup(earlierNotifs)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Notifications")
        .task { await store.reloadNotifications() }
        .refreshable { await store.reloadNotifications() }
    }

    private func notifGroup(_ items: [AppNotification]) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { notif in
                Button {
                    if !notif.isRead { store.markNotificationRead(id: notif.id) }
                } label: {
                    NotificationRow(notification: notif)
                }
                .buttonStyle(.plain)
                if notif.id != items.last?.id {
                    Rectangle().fill(theme.lineSoft).frame(height: 1)
                        .padding(.leading, 52)
                }
            }
        }
        .padding(.horizontal, 10)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
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
            IconView(icon: .bell, size: 28, color: theme.inkFaint)
                .frame(width: 64, height: 64)
                .background(theme.creamDeep, in: Circle())
                .accessibilityHidden(true)
            Text("No notifications").font(theme.display(21)).foregroundStyle(theme.ink)
            Text("Shift reminders, swap updates, and other alerts will appear here.")
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

#Preview {
    NavigationStack { NotificationsView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
