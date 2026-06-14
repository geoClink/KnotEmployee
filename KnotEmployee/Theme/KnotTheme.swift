import SwiftUI

protocol KnotTheme {
    var name: String { get }
    //surfaces
    var ink: Color { get };          var inkSoft: Color { get }
    var inkMuted: Color { get };     var inkFaint: Color { get }
    var cream: Color { get };        var creamDeep: Color { get }
    var card: Color { get };         var paper: Color { get }
    
    //accents
    var rose: Color { get }; var roseDeep: Color { get }; var roseSoft: Color { get }
    var gold: Color { get }; var green: Color { get }; var olive: Color { get }
    
    //lines
    var line: Color { get }; var lineSoft: Color { get }
    
    //shape
    var rCard: CGFloat { get }; var rCardLarge: CGFloat { get }; var rPill: CGFloat { get }
    
    //type
    func display(_ size: CGFloat) -> Font
    func body(_ size: CGFloat) -> Font
    func bodyMedium(_ size: CGFloat) -> Font
    func mono(_ size: CGFloat) -> Font
    //avatarts - derived from accents
    var avatarPalette: [Color] { get }
}

//Defaults so each client only overrides what differs.
extension KnotTheme {
    var rCard: CGFloat { 10 }
    var rCardLarge: CGFloat { 12 }
    var rPill: CGFloat { 20 }
    var avatarPalette: [Color] { [rose, green, gold, olive, roseDeep, roseSoft] }   // ← avatar, not acatar
    func avatarColor(for name: String) -> Color {
        avatarPalette[abs(name.hashValue) % avatarPalette.count]
    }
}
