import SwiftUI

struct BakeryCoTheme: KnotTheme {
    let name = "The Bakery Co."
    let ink       = Color(hex: 0x2A1810); let inkSoft   = Color(hex: 0x5E4634)
    let inkMuted  = Color(hex: 0x8B7461); let inkFaint  = Color(hex: 0xB8A48E)
    let cream     = Color(hex: 0xF4ECDD); let creamDeep = Color(hex: 0xE9DDC4)
    let card      = Color(hex: 0xFBF5E9); let paper     = Color(hex: 0xFFFCF6)
    let rose      = Color(hex: 0xC77968); let roseDeep  = Color(hex: 0xA85B4D); let roseSoft = Color(hex: 0xECD0C8)
    let gold      = Color(hex: 0xB8924A); let green     = Color(hex: 0x5C7551); let olive    = Color(hex: 0x6B6440)
    let line      = Color(hex: 0xE2D5BD); let lineSoft  = Color(hex: 0xEFE6D2)

    func display(_ s: CGFloat) -> Font    { .custom("CormorantGaramond-Medium", size: s, relativeTo: .title) }
    func body(_ s: CGFloat) -> Font       { .custom("DMSans18pt-Regular",       size: s, relativeTo: .body) }
    func bodyMedium(_ s: CGFloat) -> Font { .custom("DMSans18pt-Medium",        size: s, relativeTo: .body) }
    func mono(_ s: CGFloat) -> Font       { .custom("JetBrainsMono-Regular",    size: s, relativeTo: .body) }
}
