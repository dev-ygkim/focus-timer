import SwiftUI

enum FocusTheme {
    static let background = Color(red: 0.055, green: 0.071, blue: 0.075)
    static let surface = Color(red: 0.115, green: 0.145, blue: 0.148)
    static let elevatedSurface = Color(red: 0.145, green: 0.180, blue: 0.182)
    static let border = Color(red: 0.235, green: 0.300, blue: 0.302)
    static let mint = Color(red: 0.47, green: 0.84, blue: 0.77)
    static let mintMuted = Color(red: 0.16, green: 0.34, blue: 0.33)
    static let rest = Color(red: 0.67, green: 0.60, blue: 0.93)
    static let textPrimary = Color(red: 0.92, green: 0.96, blue: 0.95)
    static let textSecondary = Color(red: 0.62, green: 0.70, blue: 0.69)
    static let ink = Color(red: 0.045, green: 0.090, blue: 0.086)
    static let danger = Color(red: 0.96, green: 0.43, blue: 0.42)
}

struct FocusPrimaryButtonStyle: ButtonStyle {
    var tint: Color = FocusTheme.mint

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(FocusTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct FocusSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(FocusTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(FocusTheme.surface.opacity(configuration.isPressed ? 0.65 : 1.0))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(FocusTheme.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct FocusCompactButtonStyle: ButtonStyle {
    var tint: Color = FocusTheme.mint

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(FocusTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
