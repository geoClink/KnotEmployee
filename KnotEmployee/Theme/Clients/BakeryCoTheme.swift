import SwiftUI

struct BakeryCoTheme: KnotTheme {
    let name = "The Bakery Co."

    // Text
    var ink:      Color { Color(light: 0x2A1810, dark: 0xF2E8D8) }
    var inkSoft:  Color { Color(light: 0x5E4634, dark: 0xCDB89C) }
    var inkMuted: Color { Color(light: 0x8B7461, dark: 0x9E876E) }
    var inkFaint: Color { Color(light: 0xB8A48E, dark: 0x6A5645) }

    // Surfaces
    var cream:     Color { Color(light: 0xF4ECDD, dark: 0x1A0E08) }
    var creamDeep: Color { Color(light: 0xE9DDC4, dark: 0x241510) }
    var card:      Color { Color(light: 0xFBF5E9, dark: 0x2C1B12) }
    var paper:     Color { Color(light: 0xFFFCF6, dark: 0x341F14) }

    // Accents
    var rose:     Color { Color(light: 0xC77968, dark: 0xD4897A) }
    var roseDeep: Color { Color(light: 0xA85B4D, dark: 0xB8655A) }
    var roseSoft: Color { Color(light: 0xECD0C8, dark: 0x4A2820) }
    var gold:     Color { Color(light: 0xB8924A, dark: 0xC49A52) }
    var green:    Color { Color(light: 0x5C7551, dark: 0x6C8E62) }
    var olive:    Color { Color(light: 0x6B6440, dark: 0x7A7347) }

    // Lines
    var line:     Color { Color(light: 0xE2D5BD, dark: 0x3E2C1E) }
    var lineSoft: Color { Color(light: 0xEFE6D2, dark: 0x2C1A10) }

    func display(_ s: CGFloat) -> Font    { .custom("CormorantGaramond-Medium", size: s, relativeTo: .title) }
    func body(_ s: CGFloat) -> Font       { .custom("DMSans18pt-Regular",       size: s, relativeTo: .body) }
    func bodyMedium(_ s: CGFloat) -> Font { .custom("DMSans18pt-Medium",        size: s, relativeTo: .body) }
    func mono(_ s: CGFloat) -> Font       { .custom("JetBrainsMono-Regular",    size: s, relativeTo: .body) }
}
