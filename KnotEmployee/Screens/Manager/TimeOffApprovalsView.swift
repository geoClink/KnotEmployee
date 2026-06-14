import SwiftUI

struct TimeOffApprovalsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

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
                        .font(theme.body(12)).foregroundStyle(theme.inkFaint)
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

            // Conflict warning if request overlaps a scheduled shift
            if hasConflict(request) {
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

    private func hasConflict(_ request: TimeOff) -> Bool {
        // Simple conflict check: if any shift falls on the request range
        store.shift.contains { $0.date.contains(request.range.prefix(6)) }
    }

    private func approve(_ request: TimeOff) {
        if let i = store.timeOff.firstIndex(where: { $0.id == request.id }) {
            store.timeOff[i].status = .approved
        }
    }

    private func deny(_ request: TimeOff) {
        if let i = store.timeOff.firstIndex(where: { $0.id == request.id }) {
            store.timeOff[i].status = .denied
        }
    }
}

#Preview {
    NavigationStack { TimeOffApprovalsView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
