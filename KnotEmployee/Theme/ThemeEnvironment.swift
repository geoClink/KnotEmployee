import SwiftUI

private struct KnotThemeKey: EnvironmentKey {
    static let defaultValue: KnotTheme = BakeryCoTheme()
}

extension EnvironmentValues {
    var knotTheme: KnotTheme {
        get { self[KnotThemeKey.self] }
        set { self[KnotThemeKey.self] }
    }
}
