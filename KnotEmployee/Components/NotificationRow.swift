import SwiftUI

struct NotificationRow: View {
    @Environment(\.knotTheme) private var theme
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.icon)
                .font(.system(size: 16))
                .foregroundStyle(notification.isRead ? theme.inkMuted : theme.rose)
                .frame(width: 36, height: 36)
                .background(notification.isRead ? theme.creamDeep : theme.roseSoft,
                             in: RoundedRectangle(cornerRadius: theme.rCard))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(theme.bodyMedium(15))
                    .foregroundStyle(theme.ink)
                Text(notification.body)
                    .font(theme.body(13))
                    .foregroundStyle(theme.inkMuted)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(notification.timestamp)
                    .font(theme.body(11)).foregroundStyle(theme.inkFaint)
                if !notification.isRead {
                    Circle().fill(theme.rose).frame(width: 8, height: 8)
                        .accessibilityLabel("Unread")
                }
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 0) {
        NotificationRow(notification: AppNotification(icon: "calendar", title: "Shift tomorrow", body: "6:00 AM – 12:00 PM · Lead Baker", timestamp: "Just now", isRead: false, category: .shift))
        NotificationRow(notification: AppNotification(icon: "checkmark", title: "Time off approved", body: "Jun 24–26 PTO request approved.", timestamp: "Yesterday", isRead: true, category: .timeOff))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
