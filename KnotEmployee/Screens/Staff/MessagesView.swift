import SwiftUI

struct MessagesView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @State private var showCompose = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.threads.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.threads) { thread in
                            NavigationLink {
                                MessageThreadView(thread: thread)
                            } label: {
                                MessageThreadPreview(thread: thread)
                            }
                            .buttonStyle(.plain)
                            if thread.id != store.threads.last?.id {
                                Rectangle().fill(theme.lineSoft).frame(height: 1)
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Messages")
            .task { await store.reloadThreads() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCompose = true } label: {
                        IconView(icon: .plus, size: 22, color: theme.rose)
                    }
                    .accessibilityLabel("New message")
                }
            }
            .sheet(isPresented: $showCompose) { NewMessageView() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            IconView(icon: .message, size: 28, color: theme.inkFaint)
                .frame(width: 64, height: 64)
                .background(theme.creamDeep, in: Circle())
                .accessibilityHidden(true)
            Text("No messages").font(theme.display(21)).foregroundStyle(theme.ink)
            Text("Direct messages with your manager and teammates will appear here.")
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

#Preview {
    MessagesView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
