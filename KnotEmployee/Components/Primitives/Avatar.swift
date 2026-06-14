import SwiftUI

struct Avatar: View {
    @Environment(\.knotTheme) private var theme
    let name: String
    var size: CGFloat = 36

    var body: some View {
        Text(initials)
            .font(theme.bodyMedium(size * 0.4))
            .foregroundStyle(textColor)
            .frame(width: size, height: size)
            .background(bgColor, in: Circle())
    }

    private var initials: String {
        String(name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased()
    }
    // Stable hash → deterministic color (NOT String.hashValue, which changes each launch)
    private var paletteIndex: Int {
        var h = 5381
        for b in name.utf8 { h = (h &* 33) &+ Int(b) }
        let n = theme.avatarPalette.count
        return ((h % n) + n) % n
    }
    private var bgColor: Color { theme.avatarPalette[paletteIndex] }
    private var textColor: Color { paletteIndex == 5 ? theme.ink : theme.paper } // roseSoft is light
}

#Preview {
    HStack(spacing: 12) {
        ForEach(["Maya Okafor", "Devon Hale", "Priya Raman", "Theo Brandt", "Aisha Bello", "Sofia Mendez"], id: \.self) {
            Avatar(name: $0, size: 48)
        }
    }
    .padding(40)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
