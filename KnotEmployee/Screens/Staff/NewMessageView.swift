import SwiftUI

struct NewMessageView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var recipients: [StaffMember] {
        store.staff.filter { $0.id != store.currentUser.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(recipients) { person in
                        NavigationLink {
                            MessageThreadView(thread: threadFor(person))
                        } label: {
                            row(person)
                        }
                        .buttonStyle(.plain)
                        if person.id != recipients.last?.id {
                            Rectangle().fill(theme.lineSoft).frame(height: 1)
                                .padding(.leading, 66)
                        }
                    }
                }
                .padding(20)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("New message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(theme.body(15)).foregroundStyle(theme.inkSoft)
                }
            }
        }
    }

    private func row(_ person: StaffMember) -> some View {
        HStack(spacing: 12) {
            Avatar(name: person.name, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                Text(person.jobTitle).font(theme.body(13)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            IconView(icon: .chevronRight, size: 16, color: theme.inkFaint)
        }
        .padding(.vertical, 11).padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func threadFor(_ person: StaffMember) -> MessageThread {
        if let existing = store.threads.first(where: {
            $0.participantName == person.name && !$0.isBroadcast
        }) {
            return existing
        }
        return MessageThread(targetEmployeeId: person.id,
                             participantName: person.name,
                             lastMessage: "", timestamp: "Now",
                             unread: false, messages: [])
    }
}

#Preview {
    NewMessageView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
