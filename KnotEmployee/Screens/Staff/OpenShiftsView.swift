import SwiftUI

struct OpenShiftsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            if store.openShifts.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(store.openShifts) { shift in
                        OpenShiftRow(shift: shift) { pickUp(shift) }
                    }
                    footerNote
                }
                .padding(20)
            }
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Open shifts")
    }

    private func pickUp(_ shift: OpenShift) {
        if let i = store.openShifts.firstIndex(where: { $0.id == shift.id }) {
            store.openShifts[i].status = .pending   // stays visible as "Pending approval"
        }
    }

    private var footerNote: some View {
        HStack(spacing: 10) {
            IconView(icon: .clock, size: 16, color: theme.inkMuted)
            Text("Picking up a shift sends it to your manager for a quick approval before it’s yours.")
                .font(theme.body(12)).foregroundStyle(theme.inkSoft)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            IconView(icon: .handoff, size: 28, color: theme.inkFaint)
                .frame(width: 64, height: 64)
                .background(theme.creamDeep, in: Circle())
            Text("No open shifts").font(theme.display(21)).foregroundStyle(theme.ink)
            Text("When a teammate gives up a shift, it appears here for anyone qualified to claim.")
                .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

#Preview {
    NavigationStack { OpenShiftsView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
