import SwiftUI

struct ApprovalsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    private var pending: [OpenShift] { store.openShifts.filter { $0.status == .pending } }

    var body: some View {
        ScrollView {
            if pending.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(pending) { shift in approvalCard(shift) }
                }
                .padding(20)
            }
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Approvals")
    }

    private func approvalCard(_ shift: OpenShift) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                dateBlock(shift)
                VStack(alignment: .leading, spacing: 2) {
                    Text(shift.timeRange).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                    Text(shift.role).font(theme.body(12)).foregroundStyle(theme.inkMuted)
                    Text("Pickup from \(shift.offeredBy)")
                        .font(theme.body(12)).foregroundStyle(theme.inkFaint).padding(.top, 3)
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
                Button { deny(shift) } label: {
                    Text("Deny").font(theme.bodyMedium(14)).foregroundStyle(theme.inkSoft)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Capsule().strokeBorder(theme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Deny pickup from \(shift.offeredBy)")
                Button { approve(shift) } label: {
                    HStack(spacing: 6) {
                        IconView(icon: .check, size: 16, color: theme.paper)
                        Text("Approve").font(theme.bodyMedium(14)).foregroundStyle(theme.paper)
                    }
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(theme.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Approve pickup from \(shift.offeredBy)")
            }
        }
        .knotCard(padding: 13)
    }

    private func dateBlock(_ shift: OpenShift) -> some View {
        VStack(spacing: 1) {
            Text(shift.day.uppercased()).font(theme.bodyMedium(11))
            Text(shift.date.filter(\.isNumber)).font(theme.display(22))
        }
        .frame(width: 50, height: 54).foregroundStyle(theme.inkSoft)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
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
        store.openShifts.removeAll { $0.id == shift.id }   // assigned & resolved
    }
    private func deny(_ shift: OpenShift) {
        if let i = store.openShifts.firstIndex(where: { $0.id == shift.id }) {
            store.openShifts[i].status = .open             // back to available
        }
    }
}

#Preview {
    NavigationStack { ApprovalsView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
