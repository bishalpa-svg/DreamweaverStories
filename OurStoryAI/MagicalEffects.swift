import SwiftUI

// ✨ A View that emits random floating sparkles
struct SparkleEffect: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<12) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 2...5))
                        .opacity(animate ? 0 : 1)
                        .position(
                            x: CGFloat.random(in: 0...proxy.size.width),
                            y: CGFloat.random(in: 0...proxy.size.height)
                        )
                        .scaleEffect(animate ? 1.5 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 1.5...3.0))
                                .repeatForever(autoreverses: false)
                                .delay(Double.random(in: 0...2)),
                            value: animate
                        )
                }
            }
        }
        .onAppear { animate = true }
        .allowsHitTesting(false)
    }
}

// ✨ A pulsing glow for the "Max Pack" cards
struct PulsingGlow: ViewModifier {
    var active: Bool
    @State private var glow = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: active ? .yellow.opacity(glow ? 0.6 : 0.1) : .clear, radius: active ? 15 : 0)
            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glow)
            .onAppear {
                if active { glow = true }
            }
    }
}
