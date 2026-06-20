import SwiftUI

struct TimeOffApprovalsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @State private var processingIds = Set<UUID>()
    @State private var conflicts: [UUID: Bool] = [:]

    private var pending: [TimeOff] { store.timeOff.filter { $0.status == .pending } }

    var body: some View {
        ScrollView {
            if pending.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(pending) { request in
                        approvalCard(request)
                    }
                }
                .padding(20)
            }
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Time off requests")
        .task(id: pending.map(\.id)) {
            await loadConflicts()
        }
    }

    private func loadConflicts() async {
        await withTaskGroup(of: (UUID, Bool).self) { group in
            for request in pending {
                group.addTask { (request.id, await store.hasShiftConflict(for: request)) }
            }
            for await (id, hasConflict) in group {
                conflicts[id] = hasConflict
            }
        }
    }

    private func approvalCard(_ request: TimeOff) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Avatar(name: request.staffName, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.staffName)
                        .font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                    Text("\(request.kind.rawValue) · \(request.range)")
                        .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                    Text("\(request.days) day\(request.days == 1 ? "" : "s")")
                        .font(theme.body(12)).foregroundStyle(theme.inkMuted)
                }
                Spacer()
                StatusBadge(status: .pending, small: true)
            }

            if let note = request.note, !note.isEmpty {
                Text("\"\(note)\"").font(theme.body(12)).foregroundStyle(theme.inkSoft)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.cream, in: RoundedRectangle(cornerRadius: 8))
            }

            if conflicts[request.id] == true {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12)).foregroundStyle(theme.gold)
                    Text("This overlaps a scheduled shift.")
                        .font(theme.body(12)).foregroundStyle(theme.gold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                Button { deny(request) } label: {
                    Text("Deny").font(theme.bodyMedium(14)).foregroundStyle(theme.inkSoft)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Capsule().strokeBorder(theme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Deny time off for \(request.staffName)")
                .accessibilityHint("Rejects the request")

                Button { approve(request) } label: {
                    HStack(spacing: 6) {
                        IconView(icon: .check, size: 16, color: theme.paper)
                        Text("Approve").font(theme.bodyMedium(14)).foregroundStyle(theme.paper)
                    }
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(theme.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Approve time off for \(request.staffName)")
                .accessibilityHint("Grants the time off")
            }
        }
        .knotCard(padding: 13)
        .accessibilityElement(children: .contain)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            IconView(icon: .check, size: 28, color: theme.green)
                .frame(width: 64, height: 64)
                .background(theme.green.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text("All caught up").font(theme.display(21)).foregroundStyle(theme.ink)
            Text("No time off requests are waiting for your review.")
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }

    private func approve(_ request: TimeOff) {
        guard !processingIds.contains(request.id) else { return }
        processingIds.insert(request.id)
        Task { await store.approveTimeOff(id: request.id); processingIds.remove(request.id) }
    }

    private func deny(_ request: TimeOff) {
        guard !processingIds.contains(request.id) else { return }
        processingIds.insert(request.id)
        Task { await store.denyTimeOff(id: request.id); processingIds.remove(request.id) }
    }
}

#Preview {
    NavigationStack { TimeOffApprovalsView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
