import SwiftUI

struct DirectMessageBubble: View {
    @Environment(\.knotTheme) private var theme
    let message: Message

    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer(minLength: 60) }
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(theme.body(15)).foregroundStyle(textColor)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(bgColor, in: bubbleShape)
                Text(message.timestamp)
                    .font(theme.body(11)).foregroundStyle(theme.inkFaint)
            }
            if !message.isFromCurrentUser { Spacer(minLength: 60) }
        }
    }

    private var bgColor: Color { message.isFromCurrentUser ? theme.ink : theme.card }
    private var textColor: Color { message.isFromCurrentUser ? theme.paper : theme.ink }

    private var bubbleShape: some Shape {
        RoundedRectangle(cornerRadius: 16)
    }
}

#Preview {
    VStack(spacing: 8) {
        DirectMessageBubble(message: Message(senderName: "Maya Okafor", text: "Hey Elena, could I leave 30 min early?", timestamp: "1:50 PM", isFromCurrentUser: true))
        DirectMessageBubble(message: Message(senderName: "Elena Voss", text: "That should be fine — Priya can cover close.", timestamp: "2:10 PM", isFromCurrentUser: false))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
