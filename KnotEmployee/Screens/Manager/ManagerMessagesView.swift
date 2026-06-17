import SwiftUI

struct ManagerMessagesView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    enum Filter: String, CaseIterable { case all = "All", unread = "Unread", broadcast = "Broadcast" }
    @State private var filter: Filter = .all
    @State private var showCompose = false
    @State private var showBroadcast = false

    private var filteredThreads: [MessageThread] {
        switch filter {
        case .all:       store.threads.filter { !$0.isBroadcast }
        case .unread:    store.threads.filter { $0.unread && !$0.isBroadcast }
        case .broadcast: store.threads.filter(\.isBroadcast)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                ScrollView {
                    if filteredThreads.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(filteredThreads) { thread in
                                NavigationLink {
                                    MessageThreadView(thread: thread)
                                } label: {
                                    MessageThreadPreview(thread: thread)
                                }
                                .buttonStyle(.plain)
                                if thread.id != filteredThreads.last?.id {
                                    Rectangle().fill(theme.lineSoft).frame(height: 1)
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Messages")
            .task { await store.reloadThreads() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if filter == .broadcast { showBroadcast = true }
                        else { showCompose = true }
                    } label: {
                        IconView(icon: .plus, size: 22, color: theme.rose)
                    }
                    .accessibilityLabel(filter == .broadcast ? "New broadcast" : "New message")
                }
            }
            .sheet(isPresented: $showCompose) { NewMessageView() }
            .sheet(isPresented: $showBroadcast) { NewBroadcastView() }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 0) {
            ForEach(Filter.allCases, id: \.rawValue) { f in
                Button { filter = f } label: {
                    Text(f.rawValue)
                        .font(theme.bodyMedium(14))
                        .foregroundStyle(filter == f ? theme.paper : theme.ink)
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(filter == f ? theme.ink : theme.card, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(filter == f ? .isSelected : [])
            }
        }
        .padding(3)
        .background(theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
        .padding(.horizontal, 20).padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            IconView(icon: .message, size: 28, color: theme.inkFaint)
                .frame(width: 64, height: 64)
                .background(theme.creamDeep, in: Circle())
                .accessibilityHidden(true)
            Text("No messages").font(theme.display(21)).foregroundStyle(theme.ink)
            Text(filter == .unread
                 ? "You're all caught up — no unread messages."
                 : "Messages with your team will appear here.")
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

#Preview {
    ManagerMessagesView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
