import SwiftUI

// MARK: - Scheme

private struct CelebrationScheme {
    let emoji: String
    let headline: String
    let tagline: String
    let buttonLabel: String
    let accentColor: Color
    let background: Color
    let confettiHueOffset: Double   // shifts the whole rainbow so confetti feels on-theme
}

private let schemes: [CelebrationScheme] = [
    CelebrationScheme(
        emoji: "🏆",
        headline: "Personal Best!",
        tagline: "You crushed it.",
        buttonLabel: "Let's Go! 🎉",
        accentColor: .yellow,
        background: Color(red: 0.05, green: 0.04, blue: 0.0),
        confettiHueOffset: 0.0
    ),
    CelebrationScheme(
        emoji: "🔥",
        headline: "You're on Fire!",
        tagline: "Nothing can stop you now.",
        buttonLabel: "Keep Burning! 🔥",
        accentColor: .orange,
        background: Color(red: 0.12, green: 0.03, blue: 0.0),
        confettiHueOffset: 0.05
    ),
    CelebrationScheme(
        emoji: "⚡️",
        headline: "Beast Mode!",
        tagline: "Limits? What limits?",
        buttonLabel: "Unleash It! ⚡️",
        accentColor: Color(red: 0.72, green: 0.38, blue: 1.0),
        background: Color(red: 0.06, green: 0.02, blue: 0.14),
        confettiHueOffset: 0.7
    ),
    CelebrationScheme(
        emoji: "🚀",
        headline: "History Made!",
        tagline: "You just rewrote the record books.",
        buttonLabel: "Liftoff! 🚀",
        accentColor: Color(red: 0.18, green: 0.88, blue: 0.6),
        background: Color(red: 0.0, green: 0.08, blue: 0.06),
        confettiHueOffset: 0.35
    ),
    CelebrationScheme(
        emoji: "⭐️",
        headline: "All-Time High!",
        tagline: "The view from the top is worth it.",
        buttonLabel: "To the Stars! ⭐️",
        accentColor: Color(red: 0.28, green: 0.74, blue: 1.0),
        background: Color(red: 0.02, green: 0.04, blue: 0.14),
        confettiHueOffset: 0.55
    ),
]

// MARK: - View

struct PRCelebrationView: View {
    let activityNames: [String]
    let onDismiss: () -> Void

    @State private var animate = false
    @State private var scheme: CelebrationScheme = schemes[0]

    var body: some View {
        ZStack {
            scheme.background
                .opacity(0.92)
                .ignoresSafeArea()

            ConfettiLayer(animate: animate, hueOffset: scheme.confettiHueOffset)

            VStack(spacing: 28) {
                Text(scheme.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(animate ? 1.0 : 0.1)
                    .animation(.spring(response: 0.55, dampingFraction: 0.45).delay(0.15), value: animate)

                VStack(spacing: 10) {
                    Text(scheme.headline)
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundStyle(.white)

                    if activityNames.count == 1 {
                        Text(activityNames[0])
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(scheme.accentColor)
                    } else {
                        ForEach(activityNames, id: \.self) { name in
                            Text(name)
                                .font(.headline)
                                .foregroundStyle(scheme.accentColor)
                        }
                    }

                    Text(scheme.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.top, 4)
                }
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 24)
                .animation(.easeOut(duration: 0.45).delay(0.35), value: animate)

                Button(action: onDismiss) {
                    Text(scheme.buttonLabel)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 16)
                        .background(scheme.accentColor)
                        .clipShape(Capsule())
                        .shadow(color: scheme.accentColor.opacity(0.55), radius: 14, y: 4)
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.6), value: animate)
            }
            .padding(32)
        }
        .onAppear {
            scheme = schemes.randomElement()!
            animate = true
        }
    }
}

// MARK: - Confetti

private struct ConfettiLayer: View {
    let animate: Bool
    let hueOffset: Double

    var body: some View {
        ForEach(0..<60, id: \.self) { i in
            ConfettiPiece(index: i, animate: animate, hueOffset: hueOffset)
        }
    }
}

private struct ConfettiPiece: View {
    let index: Int
    let animate: Bool
    let hueOffset: Double

    private var hue: Double        { (Double(index * 37 % 360) / 360.0 + hueOffset).truncatingRemainder(dividingBy: 1.0) }
    private var xFraction: Double  { Double(index * 73 % 97) / 97.0 }
    private var delay: Double      { Double(index % 20) * 0.04 }
    private var duration: Double   { 1.0 + Double(index % 8) * 0.18 }
    private var size: Double       { 6.0 + Double(index % 7) }
    private var targetSpin: Double { Double(index * 53 % 540) }
    private var shape: Int         { index % 3 }   // 0: square, 1: circle, 2: triangle

    var body: some View {
        GeometryReader { geo in
            let x = geo.size.width * xFraction
            Group {
                switch shape {
                case 0:
                    Rectangle()
                        .frame(width: size, height: size * 0.55)
                case 1:
                    Circle()
                        .frame(width: size, height: size)
                default:
                    Triangle()
                        .frame(width: size, height: size * 0.85)
                }
            }
            .foregroundStyle(Color(hue: hue, saturation: 0.88, brightness: 0.95))
            .position(x: x, y: animate ? geo.size.height + 12 : -12)
            .rotationEffect(.degrees(animate ? targetSpin : 0))
            .animation(
                .linear(duration: duration).delay(delay),
                value: animate
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    PRCelebrationView(activityNames: ["Bench Press", "Squat"]) { }
}
