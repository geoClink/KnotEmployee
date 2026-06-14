import SwiftUI

struct LaborDay: Identifiable {
    let id = UUID()
    var day: String
    var scheduled: Double
    var actual: Double
    var budget: Double
}

struct LaborCostBar: View {
    @Environment(\.knotTheme) private var theme
    let data: LaborDay

    private var fillRatio: CGFloat { min(data.actual / max(data.budget, 1), 1.0) }
    private var overBudget: Bool { data.actual > data.budget }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(data.day).font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
                Spacer()
                Text("$\(data.actual, specifier: "%.0f")")
                    .font(theme.mono(13)).foregroundStyle(overBudget ? theme.roseDeep : theme.ink)
                Text("/ $\(data.budget, specifier: "%.0f")")
                    .font(theme.body(12)).foregroundStyle(theme.inkMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.creamDeep)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(overBudget ? theme.roseDeep : theme.green)
                        .frame(width: geo.size.width * fillRatio, height: 8)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Labor cost, \(data.day)")
        .accessibilityValue("$\(data.actual, specifier: "%.0f") of $\(data.budget, specifier: "%.0f") budget")
    }
}

#Preview {
    VStack(spacing: 16) {
        LaborCostBar(data: LaborDay(day: "Monday", scheduled: 388, actual: 372, budget: 412))
        LaborCostBar(data: LaborDay(day: "Tuesday", scheduled: 410, actual: 425, budget: 412))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
