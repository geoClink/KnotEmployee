import SwiftUI

struct NewBroadcastView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var messageText = ""

    private var recipientCount: Int {
        store.staff.filter { $0.role == .staff }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    recipientBanner
                    messageField
                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Broadcast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(theme.body(15)).foregroundStyle(theme.inkSoft)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: send) {
                        Text("Send").font(theme.bodyMedium(15))
                            .foregroundStyle(messageText.isEmpty ? theme.inkFaint : theme.rose)
                    }
                    .disabled(messageText.isEmpty)
                }
            }
        }
    }

    private var recipientBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "megaphone.fill")
                .font(.system(size: 18))
                .foregroundStyle(theme.rose)
                .frame(width: 44, height: 44)
                .background(theme.roseSoft.opacity(0.3), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("All Staff").font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                Text("\(recipientCount) recipients").font(theme.body(13)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
        }
        .knotCard(padding: 13)
        .accessibilityElement(children: .combine)
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MESSAGE").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            TextField("Write your announcement...", text: $messageText, axis: .vertical)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .lineLimit(4...10)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private func send() {
        guard !messageText.isEmpty else { return }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        let timestamp = fmt.string(from: Date())
        let thread = MessageThread(
            participantName: "All Staff",
            lastMessage: messageText,
            timestamp: timestamp,
            unread: false,
            messages: [
                Message(senderName: store.currentUser.name, text: messageText,
                        timestamp: timestamp, isFromCurrentUser: true)
            ],
            isBroadcast: true,
            broadcastRecipientCount: recipientCount
        )
        store.threads.insert(thread, at: 0)
        dismiss()
    }
}

#Preview {
    NewBroadcastView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
