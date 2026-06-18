import SwiftUI

struct AvailabilityView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    @State private var availability: [Bool] = [Bool](repeating: true, count: 7)
    @State private var isSaving = false
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                infoCard
                VStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                        HStack(spacing: 12) {
                            Text(day).font(theme.body(15)).foregroundStyle(theme.ink)
                            Spacer()
                            Toggle("", isOn: $availability[i])
                                .labelsHidden()
                                .tint(theme.green)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 13)
                        if i < days.count - 1 {
                            Rectangle().fill(theme.lineSoft).frame(height: 1)
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))

                if saved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.green)
                        Text("Availability saved").font(theme.body(14)).foregroundStyle(theme.green)
                    }
                }

                Button(action: save) {
                    Group {
                        if isSaving { ProgressView().tint(theme.paper) }
                        else { Text("Save availability").font(theme.bodyMedium(15)).foregroundStyle(theme.paper) }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(theme.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
            .padding(20)
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Availability")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { availability = store.availability }
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 16)).foregroundStyle(theme.rose)
                .frame(width: 32, height: 32)
                .background(theme.rose.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            Text("Toggle the days you're available to work. Your manager will see this when building the schedule.")
                .font(theme.body(13)).foregroundStyle(theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(theme.rose.opacity(0.08), in: RoundedRectangle(cornerRadius: theme.rCard))
    }

    private func save() {
        isSaving = true
        saved = false
        Task {
            await store.saveAvailability(availability)
            isSaving = false
            saved = true
        }
    }
}

#Preview {
    NavigationStack { AvailabilityView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
