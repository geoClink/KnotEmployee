import SwiftUI

struct SwapRequestsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @State private var showNewSwap = false

    var body: some View {
        ScrollView {
            if store.swaps.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(store.swaps) { swap in
                        SwapRequestRow(swap: swap)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if swap.status == .pending && swap.direction == .outgoing {
                                    Button(role: .destructive) {
                                        Task { await store.cancelSwap(id: swap.id) }
                                    } label: {
                                        Label("Cancel", systemImage: "xmark")
                                    }
                                }
                            }
                    }
                    footerNote
                }
                .padding(20)
            }
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Swap requests")
        .refreshable { try? await store.loadInitialData() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewSwap = true } label: {
                    IconView(icon: .plus, size: 22, color: theme.rose)
                }
                .accessibilityLabel("New swap request")
            }
        }
        .sheet(isPresented: $showNewSwap) {
            NewSwapView()
        }
    }

    private var footerNote: some View {
        HStack(spacing: 10) {
            IconView(icon: .swap, size: 16, color: theme.inkMuted)
            Text("Swaps require manager approval before they take effect.")
                .font(theme.body(12)).foregroundStyle(theme.inkSoft)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            IconView(icon: .swap, size: 28, color: theme.inkFaint)
                .frame(width: 64, height: 64)
                .background(theme.creamDeep, in: Circle())
                .accessibilityHidden(true)
            Text("No swap requests").font(theme.display(21)).foregroundStyle(theme.ink)
            Text("When you request to swap a shift with a teammate, it will appear here.")
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

#Preview {
    SwapRequestsView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
