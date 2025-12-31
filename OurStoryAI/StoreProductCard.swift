import SwiftUI
import StoreKit

struct StoreProductCard: View {
    let product: Product
    let manager: StoreKitManager
    let onBuy: () -> Void

    @State private var isPressed = false
    @State private var floatAnimation = false

    var body: some View {
        Button(action: onBuy) {
            ZStack {
                // 1. Dynamic Gradient Background
                manager.cardGradient(for: product.id)
                
                // 2. Glassmorphic Overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                
                // 3. Sparkles for high tier items
                if product.id.contains("50") || product.id.contains("100") {
                    SparkleEffect()
                }

                VStack(spacing: 4) { // Tighter spacing
                    
                    // Marketing Title
                    Text(manager.marketingTitle(for: product.id))
                        .font(.system(size: 15, weight: .bold, design: .rounded)) // Smaller font
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(.top, 10)

                    // BADGE (Middle)
                    if let badge = manager.badge(for: product.id) {
                        Text(badge)
                            .font(.system(size: 8, weight: .black))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(6)
                            .shadow(radius: 2)
                    } else {
                        // Spacer to keep alignment if no badge
                        Spacer().frame(height: 18)
                    }

                    // Catchy Description
                    Text(manager.marketingDescription(for: product.id))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 4)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                    
                    // Credit Count (Small)
                    Text(product.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))

                    // Price Pill
                    Text(product.displayPrice)
                        .font(.system(size: 16, weight: .heavy, design: .rounded)) // Smaller price tag
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(10)
                        .padding(.bottom, 10)
                }
            }
            .frame(height: 145) // ✅ Reduced height to fit all on screen
            .cornerRadius(16)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .offset(y: floatAnimation ? -1 : 1) // Subtle float
            .animation(.spring(response: 0.3), value: isPressed)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatAnimation)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        // Glow effect
        .modifier(PulsingGlow(active: product.id.contains("50") || product.id.contains("100")))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.5)) {
                floatAnimation = true
            }
        }
    }
}
