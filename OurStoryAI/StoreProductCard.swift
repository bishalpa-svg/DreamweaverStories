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
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                
                // 3. Sparkles for high tier items
                if product.id.contains("25") || product.id.contains("50") || product.id.contains("100") {
                    SparkleEffect()
                }

                VStack(spacing: 6) {
                    
                    // Marketing Title
                    Text(manager.marketingTitle(for: product.id))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(.top, 12)

                    // ✅ NEW LOCATION: BADGE
                    if let badge = manager.badge(for: product.id) {
                        Text(badge)
                            .font(.system(size: 9, weight: .black))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .padding(.vertical, 2) // Add a little spacing
                    }

                    // Catchy Description
                    Text(manager.marketingDescription(for: product.id))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 6)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                    
                    // Credit Count (Small)
                    Text(product.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))

                    // Price Pill
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(12)
                        .padding(.bottom, 12)
                }
                // ✅ OLD BADGE LOCATION REMOVED FROM HERE
            }
            .frame(height: 180)
            .cornerRadius(20)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .offset(y: floatAnimation ? -2 : 2)
            .animation(.spring(response: 0.3), value: isPressed)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatAnimation)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .modifier(PulsingGlow(active: product.id.contains("50") || product.id.contains("100")))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.5)) {
                floatAnimation = true
            }
        }
    }
}
