import Foundation

/// Mint accents follow DESIGN.md; warm furniture colors retain the room's original materials.
enum CozyRoomPalette {
    static let mint = "#8FB8AE"
    static let floorMint = "#D5E0D9"
    static let softMint = "#E3EEEA"
    static let ivory = "#FBF7EF"
    static let surface = "#FFFDF8"
    static let border = "#E8DDCB"
    static let wood = "#E7C7AF"
    static let detail = "#9B8274"
    static let cream = "#FFF0D9"
    static let peach = "#F5DAC1"
    static let blush = "#E8BECD"
    static let lavender = "#C4BADF"

    static func color(for name: String, kind: FurnitureKind, fallback: String) -> String {
        let part = name.replacingOccurrences(of: ".pile", with: "")
        let base = [mint, floorMint, softMint, ivory, surface, border, wood, detail, cream, peach, blush, lavender].contains(fallback)
            ? fallback : kind.defaultColorName
        switch kind {
        case .wall:
            if part.hasPrefix("window.") || part.hasPrefix("skirting.") { return wood }
            if part == "wall.back" { return cream }
            if part.hasPrefix("wall.stripe.") { return border }
            return ivory
        case .floor:
            return part == "floor.tile" ? base : floorMint
        case .bed:
            switch part {
            case "frame", "headboard", "leg", "leg.foot": return wood
            case "duvet.fold", "duvet.fold.drape": return softMint
            case "mattress": return cream
            case "pillow": return blush
            default: return base
            }
        case .desk:
            switch part {
            case "leg", "leg.foot": return wood
            case "notebook.lower.cover": return lavender
            case "notebook.cover": return blush
            case "pencil.cup": return mint
            case "notebook.pages": return cream
            case "pencil": return detail
            default: return base
            }
        case .chair:
            return part == "leg" || part == "leg.foot" ? wood : base
        case .rugRound, .rugSquare: return base
        case .sofa, .flowerCushion:
            if part == "flower.petal" { return kind == .sofa ? cream : base }
            return part == "flower.center" ? peach : base
        case .shelf:
            if part == "book.cover" || part == "book.spine" {
                // Keep a small mix of book colors on both baked and procedural models.
                if ["#B8B1DA", "#C4BADF"].contains(fallback) { return lavender }
                if ["#E9AAB8", "#E8BECD"].contains(fallback) { return blush }
                return base
            }
            if part.contains("leaf") { return mint }
            if part == "plant.bud" || part == "shelf.flower" { return blush }
            if part == "book.pages" || part == "pot" { return cream }
            if part == "book.detail" || part == "shelf.flower.center" { return peach }
            return base
        case .plant:
            if part == "pot" { return peach }
            return part == "stem" ? detail : base
        case .frame:
            if part == "mat" { return surface }
            return part.hasPrefix("heart") || part.isEmpty ? blush : base
        case .lamp:
            if part == "base" { return mint }
            return part == "stem" ? wood : base
        }
    }
}
