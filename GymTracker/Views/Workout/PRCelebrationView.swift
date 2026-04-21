import SwiftUI

struct PRCelebrationView: View {
    let activityNames: [String]
    let onDismiss: () -> Void

    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Confetti layer (non-interactive)
            ConfettiLayer(animate: animate)

            // Content card
            VStack(spacing: 28) {
                Text("🏆")
                    .font(.system(size: 80))
                    .scaleEffect(animate ? 1.0 : 0.1)
                    .animation(.spring(response: 0.55, dampingFraction: 0.45).delay(0.15), value: animate)

                VStack(spacing: 10) {
                    Text("Personal Best!")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundStyle(.white)

                    if activityNames.count == 1 {
                        Text(activityNames[0])
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.yellow)
                    } else {
                        ForEach(activityNames, id: \.self) { name in
                            Text(name)
                                .font(.headline)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 24)
                .animation(.easeOut(duration: 0.45).delay(0.35), value: animate)

                Button(action: onDismiss) {
                    Text("Let's Go! 🎉")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 16)
                        .background(.yellow)
                        .clipShape(Capsule())
                        .shadow(color: .yellow.opacity(0.5), radius: 12, y: 4)
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.6), value: animate)
            }
            .padding(32)
        }
        .onAppear { animate = true }
    }
}

// MARK: - Confetti

private struct ConfettiLayer: View {
    let animate: Bool

    var body: some View {
        // Two waves: immediate burst + slightly delayed wave
        ForEach(0..<60, id: \.self) { i in
            ConfettiPiece(index: i, animate: animate)
        }
    }
}

private struct ConfettiPiece: View {
    let index: Int
    let animate: Bool

    // Deterministic pseudo-random values based on index
    private var hue: Double        { Double(index * 37 % 360) / 360.0 }
    private var xFraction: Double  { Double(index * 73 % 97) / 97.0 }
    private var delay: Double      { Double(index % 20) * 0.04 }
    private var duration: Double   { 1.0 + Double(index % 8) * 0.18 }
    private var size: Double       { 6.0 + Double(index % 7) }
    private var targetSpin: Double { Double(index * 53 % 540) }
    private var isSquare: Bool     { index % 3 == 0 }

    var body: some View {
        GeometryReader { geo in
            let x = geo.size.width * xFraction
            Group {
                if isSquare {
                    Rectangle()
                        .frame(width: size, height: size * 0.55)
                } else {
                    Circle()
                        .frame(width: size, height: size)
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

#Preview {
    PRCelebrationView(activityNames: ["Bench Press", "Squat"]) { }
}
