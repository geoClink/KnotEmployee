import SwiftUI

struct MessageThreadPreview: View {
    @Environment(\.knotTheme) private var theme
    let thread: MessageThread

    var body: some View {
        HStack(spacing: 12) {
            Avatar(name: thread.participantName, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(thread.participantName)
                        .font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                    Spacer()
                    Text(thread.timestamp)
                        .font(theme.body(12)).foregroundStyle(theme.inkMuted)
                }
                Text(thread.lastMessage)
                    .font(theme.body(13))
                    .foregroundStyle(thread.unread ? theme.ink : theme.inkMuted)
                    .lineLimit(1)
            }
            if thread.unread {
                Circle().fill(theme.rose).frame(width: 8, height: 8)
                    .accessibilityLabel("Unread")
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 0) {
        MessageThreadPreview(thread: MessageThread(participantName: "Elena Voss", lastMessage: "Sounds good, see you then!", timestamp: "2:15 PM", unread: true, messages: []))
        MessageThreadPreview(thread: MessageThread(participantName: "Aisha Bello", lastMessage: "Can you cover my Saturday close?", timestamp: "Yesterday", unread: false, messages: []))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
