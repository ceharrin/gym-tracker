import SwiftUI

enum GymTheme {
    static let electricBlue = Color(red: 0.15, green: 0.49, blue: 0.98)
    static let brightBlue = Color(red: 0.30, green: 0.70, blue: 1.00)
    static let ink = Color(red: 0.06, green: 0.08, blue: 0.12)
    static let graphite = Color(red: 0.12, green: 0.15, blue: 0.20)
    static let steel = Color(red: 0.47, green: 0.54, blue: 0.64)
    static let mist = Color(red: 0.92, green: 0.95, blue: 0.99)

    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.99, blue: 1.0),
            Color(red: 0.94, green: 0.96, blue: 0.99),
            Color(red: 0.90, green: 0.93, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroBackground = LinearGradient(
        colors: [ink, graphite, electricBlue.opacity(0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = LinearGradient(
        colors: [Color.white.opacity(0.92), mist.opacity(0.96)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkCardBackground = LinearGradient(
        colors: [graphite, ink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surfaceStroke = LinearGradient(
        colors: [Color.white.opacity(0.75), steel.opacity(0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonBackground = LinearGradient(
        colors: [electricBlue, brightBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct GymCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var dark: Bool = false

    func body(content: Content) -> some View {
        content
            .background(dark ? AnyShapeStyle(GymTheme.darkCardBackground) : AnyShapeStyle(GymTheme.cardBackground))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(GymTheme.surfaceStroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: GymTheme.ink.opacity(dark ? 0.26 : 0.10), radius: dark ? 22 : 16, x: 0, y: dark ? 14 : 10)
    }
}

extension View {
    func gymCard(cornerRadius: CGFloat = 20, dark: Bool = false) -> some View {
        modifier(GymCardModifier(cornerRadius: cornerRadius, dark: dark))
    }
}
