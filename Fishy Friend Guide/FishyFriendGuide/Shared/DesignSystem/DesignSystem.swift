import SwiftUI

// MARK: - Arbor & Current Design System
// Colors defined on both Color (for use as Color values) and on ShapeStyle (for dot-syntax in foregroundStyle/tint)

private extension Color {
    static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,255,255,255)
        }
        return Color(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: Color tokens (use as Color.appPrimary)
extension Color {
    init(hex: String) {
        self = Color.hex(hex)
    }

    static let appPrimary             = Color.hex("#004c28")
    static let appPrimaryDim          = Color.hex("#006738")
    static let onPrimaryContainer     = Color.hex("#8de3a7")
    static let appSecondary           = Color.hex("#1d6587")
    static let secondaryContainer     = Color.hex("#98d6fe")
    static let appBackground          = Color.hex("#f8faf8")
    static let surfaceContainer       = Color.hex("#eceeec")
    static let surfaceContainerLow    = Color.hex("#f2f4f2")
    static let surfaceContainerHigh   = Color.hex("#e6e9e7")
    static let surfaceContainerHighest = Color.hex("#e1e3e1")
    static let onSurface              = Color.hex("#191c1b")
    static let onSurfaceVariant       = Color.hex("#3f4941")
    static let appOutline             = Color.hex("#6f7a70")
    static let outlineVariant         = Color.hex("#bec9be")
    static let conservationGold       = Color.hex("#C5A352")
    static let charcoalBark           = Color.hex("#333333")
    static let statusOpen             = Color.hex("#006738")
    static let statusClosed           = Color.hex("#ba1a1a")
    static let statusRestricted       = Color.hex("#C5A352")
}

// MARK: ShapeStyle tokens — enables `.appPrimary` dot syntax in foregroundStyle, tint, etc.
extension ShapeStyle where Self == Color {
    static var appPrimary: Color             { .hex("#004c28") }
    static var appPrimaryDim: Color          { .hex("#006738") }
    static var appSecondary: Color           { .hex("#1d6587") }
    static var appBackground: Color          { .hex("#f8faf8") }
    static var surfaceContainer: Color       { .hex("#eceeec") }
    static var surfaceContainerLow: Color    { .hex("#f2f4f2") }
    static var surfaceContainerHigh: Color   { .hex("#e6e9e7") }
    static var surfaceContainerHighest: Color { .hex("#e1e3e1") }
    static var onSurface: Color              { .hex("#191c1b") }
    static var onSurfaceVariant: Color       { .hex("#3f4941") }
    static var appOutline: Color             { .hex("#6f7a70") }
    static var outlineVariant: Color         { .hex("#bec9be") }
    static var conservationGold: Color       { .hex("#C5A352") }
    static var charcoalBark: Color           { .hex("#333333") }
    static var statusOpen: Color             { .hex("#006738") }
    static var statusClosed: Color           { .hex("#ba1a1a") }
    static var statusRestricted: Color       { .hex("#C5A352") }
}

// MARK: - Typography

extension Font {
    /// Source Sans 3 equivalent — display
    static let displayLg: Font = .system(size: 48, weight: .bold, design: .default)
    static let headlineLg: Font = .system(size: 32, weight: .bold)
    static let headlineMd: Font = .system(size: 24, weight: .semibold)
    static let headlineSm: Font = .system(size: 20, weight: .semibold)
    static let bodyLg: Font    = .system(size: 18, weight: .regular)
    static let bodyMd: Font    = .system(size: 16, weight: .regular)
    /// Hanken Grotesk equivalent — labels
    static let labelLg: Font   = .system(size: 14, weight: .semibold, design: .rounded)
    static let labelMd: Font   = .system(size: 12, weight: .medium, design: .rounded)
    /// JetBrains Mono equivalent — data
    static let monoData: Font  = .system(size: 13, weight: .regular, design: .monospaced)
}

// MARK: - Corner Radii

enum AppRadius {
    static let sm: CGFloat   = 2
    static let md: CGFloat   = 4
    static let lg: CGFloat   = 8
    static let xl: CGFloat   = 12
    static let full: CGFloat = 9999
}

// MARK: - Shadows

extension View {
    func appCardShadow() -> some View {
        self.shadow(color: Color.charcoalBark.opacity(0.08), radius: 12, x: 0, y: 2)
    }

    func appSubtleShadow() -> some View {
        self.shadow(color: Color.charcoalBark.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Liquid Glass Surface Modifiers
// Gates on macOS 26+; falls back to .regularMaterial on earlier systems.

extension View {
    /// Float panel glass — used for map overlays, inspector panels, control panels.
    /// The glass blurs map content behind it; tinted subtly with Evergreen.
    func floatGlass(cornerRadius: CGFloat = AppRadius.lg, tint: Color? = nil) -> some View {
        modifier(FloatGlassModifier(cornerRadius: cornerRadius, tint: tint))
    }

    /// Card glass — used for content cards, spot cards, catch record cards.
    func cardGlass(cornerRadius: CGFloat = AppRadius.lg) -> some View {
        modifier(CardGlassModifier(cornerRadius: cornerRadius))
    }

    /// Chip glass — used for tag chips and small label pills.
    func chipGlass() -> some View {
        modifier(ChipGlassModifier())
    }

    /// Sidebar item glass — interactive glass for nav items.
    func sidebarItemGlass(isSelected: Bool) -> some View {
        modifier(SidebarItemGlassModifier(isSelected: isSelected))
    }
}

private struct FloatGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            let glass: Glass = tint.map { .regular.tint($0) } ?? .regular
            content
                .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.outlineVariant, lineWidth: 1))
        }
    }
}

private struct CardGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(Color.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.outlineVariant, lineWidth: 1))
        }
    }
}

private struct ChipGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .glassEffect(.regular, in: .capsule)
        } else {
            content
                .background(Color.surfaceContainerHighest)
                .clipShape(Capsule())
        }
    }
}

private struct SidebarItemGlassModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            if isSelected {
                content
                    .glassEffect(.regular.tint(Color.appPrimary).interactive(), in: .rect(cornerRadius: AppRadius.md))
            } else {
                // unselected: hover-reactive glass (no tint)
                content
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.md))
                    // visually hide the glass until hover via tint opacity trick
                    .opacity(0.6)
            }
        } else {
            content
                .background(
                    isSelected ? Color.appPrimary.opacity(0.1) : Color.clear,
                    in: RoundedRectangle(cornerRadius: AppRadius.md)
                )
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: RegulationStatus
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
            Text(status.rawValue.uppercased())
                .font(compact ? .labelMd : .labelLg)
                .foregroundStyle(statusColor)
        }
    }

    private var statusColor: Color {
        switch status {
        case .open: return .statusOpen
        case .closed: return .statusClosed
        case .checkRegulations: return .statusRestricted
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let label: String
    var color: Color = .surfaceContainerHighest
    var textColor: Color = .onSurfaceVariant

    var body: some View {
        Text(label.uppercased())
            .font(.labelMd)
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (String, () -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headlineSm)
                    .foregroundStyle(Color.onSurface)
                if let subtitle {
                    Text(subtitle)
                        .font(.bodyMd)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
            Spacer()
            if let (label, onTap) = action {
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Text(label)
                            .font(.labelLg)
                            .foregroundStyle(Color.appSecondary)
                        Image(systemName: "arrow.forward")
                            .font(.caption.bold())
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
