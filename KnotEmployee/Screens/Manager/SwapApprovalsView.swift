import SwiftUI

struct ApprovalsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @State private var processingIds = Set<UUID>()

    private var pendingPickups: [OpenShift] { store.openShifts.filter { $0.status == .pending } }
    private var pendingSwaps: [Swap] { store.swaps.filter { $0.status == .pending } }
    private var allEmpty: Bool { pendingPickups.isEmpty && pendingSwaps.isEmpty }

    var body: some View {
        ScrollView {
            if allEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    if !pendingPickups.isEmpty {
                        sectionHeader("Open shift pickups")
                        VStack(spacing: 12) {
                            ForEach(pendingPickups) { shift in approvalCard(shift) }
                        }
                    }
                    if !pendingSwaps.isEmpty {
                        sectionHeader("Shift swaps")
                        VStack(spacing: 12) {
                            ForEach(pendingSwaps) { swap in swapCard(swap) }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Approvals")
        .refreshable { try? await store.loadInitialData() }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(theme.display(18)).foregroundStyle(theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func approvalCard(_ shift: OpenShift) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                dateBlock(shift)
                VStack(alignment: .leading, spacing: 2) {
                    Text(shift.timeRange).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                    Text(shift.role).font(theme.body(12)).foregroundStyle(theme.inkMuted)
                    Text("Pickup from \(shift.offeredBy)")
                        .font(theme.body(12)).foregroundStyle(theme.inkMuted).padding(.top, 3)
                }
                Spacer()
                StatusBadge(status: .pending, small: true)
            }
            if let reason = shift.reason, !reason.isEmpty {
                Text("“\(reason)”").font(theme.body(12)).foregroundStyle(theme.inkSoft)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.cream, in: RoundedRectangle(cornerRadius: 8))
            }
            HStack(spacing: 8) {
                Button { hapticNotification(.warning); deny(shift) } label: {
                    Text("Deny").font(theme.bodyMedium(14)).foregroundStyle(theme.inkSoft)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Capsule().strokeBorder(theme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Deny pickup from \(shift.offeredBy)")
                .accessibilityHint("Rejects the open shift pickup")
                Button { hapticNotification(.success); approve(shift) } label: {
                    HStack(spacing: 6) {
                        IconView(icon: .check, size: 16, color: theme.paper)
                        Text("Approve").font(theme.bodyMedium(14)).foregroundStyle(theme.paper)
                    }
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(theme.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Approve pickup from \(shift.offeredBy)")
                .accessibilityHint("Assigns the shift to this employee")
            }
        }
        .knotCard(padding: 13)
    }

    private func dateBlock(_ shift: OpenShift) -> some View {
        VStack(spacing: 1) {
            Text(shift.day.uppercased()).font(theme.bodyMedium(11))
            Text(shift.date.filter(\.isNumber)).font(theme.display(22))
        }
        .frame(minHeight: 54).frame(width: 50).foregroundStyle(theme.inkSoft)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
    }

    private func swapCard(_ swap: Swap) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Avatar(name: swap.fromName, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(swap.fromName).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                    Text("Wants to swap with \(swap.withName)")
                        .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                }
                Spacer()
                StatusBadge(status: .pending, small: true)
            }
            HStack(spacing: 8) {
                Button { hapticNotification(.warning); denySwap(swap) } label: {
                    Text("Deny").font(theme.bodyMedium(14)).foregroundStyle(theme.inkSoft)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Capsule().strokeBorder(theme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Deny swap request from \(swap.fromName)")
                .accessibilityHint("Rejects the swap")
                Button { hapticNotification(.success); approveSwap(swap) } label: {
                    HStack(spacing: 6) {
                        IconView(icon: .check, size: 16, color: theme.paper)
                        Text("Approve").font(theme.bodyMedium(14)).foregroundStyle(theme.paper)
                    }
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(theme.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Approve swap request from \(swap.fromName)")
                .accessibilityHint("Confirms the shift swap between both employees")
            }
        }
        .knotCard(padding: 13)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            IconView(icon: .check, size: 28, color: theme.green)
                .frame(width: 64, height: 64)
                .background(theme.green.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text("All caught up").font(theme.display(21)).foregroundStyle(theme.ink)
            Text("No pickups or swaps are waiting on you.")
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }

    private func approve(_ shift: OpenShift) {
        guard !processingIds.contains(shift.id) else { return }
        processingIds.insert(shift.id)
        Task { await store.approveShiftPickup(id: shift.id); processingIds.remove(shift.id) }
    }
    private func deny(_ shift: OpenShift) {
        guard !processingIds.contains(shift.id) else { return }
        processingIds.insert(shift.id)
        Task { await store.denyShiftPickup(id: shift.id); processingIds.remove(shift.id) }
    }
    private func approveSwap(_ swap: Swap) {
        guard !processingIds.contains(swap.id) else { return }
        processingIds.insert(swap.id)
        Task { await store.approveSwap(id: swap.id); processingIds.remove(swap.id) }
    }
    private func denySwap(_ swap: Swap) {
        guard !processingIds.contains(swap.id) else { return }
        processingIds.insert(swap.id)
        Task { await store.denySwap(id: swap.id); processingIds.remove(swap.id) }
    }
}

#Preview {
    NavigationStack { ApprovalsView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
