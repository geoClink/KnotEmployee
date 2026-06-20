import SwiftUI

struct MessageThreadView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    let thread: MessageThread
    @State private var newMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(thread.messages) { message in
                        DirectMessageBubble(message: message)
                    }
                }
                .padding(20)
            }
            inputBar
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle(thread.participantName)
        .navigationBarTitleDisplayMode(.inline)
        .task { if let id = thread.dbId { store.markThreadRead(dbId: id) } }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $newMessage)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
            Button(action: sendMessage) {
                IconView(icon: .send, size: 20, color: newMessage.isEmpty ? theme.inkFaint : theme.rose)
                    .frame(width: Layout.tapMin, height: Layout.tapMin)
            }
            .buttonStyle(.plain)
            .disabled(newMessage.isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(theme.cream)
        .overlay(alignment: .top) { Rectangle().fill(theme.line).frame(height: 1) }
    }

    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        let text = newMessage
        newMessage = ""
        Task {
            if let dbId = thread.dbId {
                try? await store.sendMessage(threadId: dbId, text: text)
            } else if let targetId = thread.targetEmployeeId {
                try? await store.createThread(withEmployeeId: targetId, initialMessage: text)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessageThreadView(thread: MessageThread(
            participantName: "Elena Voss",
            lastMessage: "Sounds good!",
            timestamp: "2:15 PM",
            unread: false,
            messages: [
                Message(senderName: "Maya Okafor", text: "Hey Elena, could I leave 30 min early?", timestamp: "1:50 PM", isFromCurrentUser: true),
                Message(senderName: "Elena Voss", text: "That should be fine — Priya can cover close.", timestamp: "2:10 PM", isFromCurrentUser: false),
                Message(senderName: "Maya Okafor", text: "Perfect, thank you!", timestamp: "2:12 PM", isFromCurrentUser: true),
                Message(senderName: "Elena Voss", text: "Sounds good, see you then!", timestamp: "2:15 PM", isFromCurrentUser: false)
            ]
        ))
    }
    .environment(\.knotTheme, BakeryCoTheme())
    .environment(AppStore.sample)
}
