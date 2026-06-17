import SwiftUI

struct NewSwapView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedShift: Shift?
    @State private var selectedPerson: StaffMember?
    @State private var note = ""

    private var teammates: [StaffMember] {
        store.staff.filter { $0.id != store.currentUser.id && $0.role == .staff }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    shiftPicker
                    personPicker
                    noteField
                    submitButton
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("New swap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(theme.body(15)).foregroundStyle(theme.inkSoft)
                }
            }
        }
    }

    private var shiftPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR SHIFT").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            VStack(spacing: 8) {
                ForEach(store.shift) { shift in
                    Button { selectedShift = shift } label: {
                        HStack(spacing: 12) {
                            VStack(spacing: 1) {
                                Text(shift.day.uppercased()).font(theme.bodyMedium(11))
                                Text(shift.date.filter(\.isNumber)).font(theme.display(22))
                            }
                            .frame(width: 50, height: 54)
                            .foregroundStyle(theme.inkSoft)
                            .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(shift.timeRange).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                                Text(shift.role).font(theme.body(13)).foregroundStyle(theme.inkMuted)
                            }
                            Spacer()
                            if selectedShift?.id == shift.id {
                                IconView(icon: .check, size: 18, color: theme.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .knotCard(padding: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.rCard)
                            .strokeBorder(selectedShift?.id == shift.id ? theme.green : .clear, lineWidth: 2)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAddTraits(selectedShift?.id == shift.id ? .isSelected : [])
                }
            }
        }
    }

    private var personPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SWAP WITH").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                ForEach(teammates) { person in
                    Button { selectedPerson = person } label: {
                        HStack(spacing: 12) {
                            Avatar(name: person.name, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.name).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                                Text(person.jobTitle).font(theme.body(12)).foregroundStyle(theme.inkMuted)
                            }
                            Spacer()
                            if selectedPerson?.id == person.id {
                                IconView(icon: .check, size: 18, color: theme.green)
                            }
                        }
                        .padding(.vertical, 11).padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAddTraits(selectedPerson?.id == person.id ? .isSelected : [])

                    if person.id != teammates.last?.id {
                        Rectangle().fill(theme.lineSoft).frame(height: 1).padding(.leading, 54)
                    }
                }
            }
            .padding(.horizontal, 10)
            .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
            .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTE (OPTIONAL)").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
                .padding(.leading, 4)
            TextField("Reason for swap", text: $note, axis: .vertical)
                .font(theme.body(15)).foregroundStyle(theme.ink)
                .lineLimit(3...6)
                .padding(14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        }
    }

    private var submitButton: some View {
        Button(action: submit) {
            HStack(spacing: 6) {
                IconView(icon: .check, size: 16, color: theme.paper)
                Text("Request swap").font(theme.bodyMedium(15)).foregroundStyle(theme.paper)
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background((selectedShift != nil && selectedPerson != nil) ? theme.ink : theme.inkFaint,
                         in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(selectedShift == nil || selectedPerson == nil)
        .accessibilityLabel("Request swap")
    }

    private func submit() {
        guard let person = selectedPerson else { return }
        store.swaps.append(
            Swap(fromName: store.currentUser.name, direction: .outgoing, status: .pending, withName: person.name)
        )
        dismiss()
    }
}

#Preview {
    NewSwapView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
