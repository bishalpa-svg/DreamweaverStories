import SwiftUI
import StoreKit

struct StoreView: View {

    @ObservedObject var creditManager = CreditManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showRestoreMessage = false

    // Grid Layout: 2 Columns
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            // Dark Magical Background
            FancyBackground()
            
            // Background Sparkles
            SparkleEffect().opacity(0.3)

            VStack(spacing: 10) { // Reduced global spacing
                
                // MARK: - Compact Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    // Balance Display (Compact)
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                        Text("\(creditManager.currentCredits)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .padding(.horizontal)
                .padding(.top, 10) // Small top padding
                
                VStack(spacing: 2) {
                    Text("Story Store")
                        .font(.title2.bold()) // Slightly smaller title
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    Text("Choose your magical bundle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 5)

                // MARK: - The Grid
                // We keep ScrollView for safety on iPhone SE/Mini, but on larger phones it won't need to scroll.
                ScrollView(showsIndicators: false) {
                    if storeManager.products.isEmpty {
                        VStack(spacing: 20) {
                            ProgressView().tint(.white)
                            Text("Summoning bundles...").foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 50)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(storeManager.products) { product in
                                StoreProductCard(
                                    product: product,
                                    manager: storeManager
                                ) {
                                    Task { await storeManager.purchase(product) }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // MARK: - Compact Footer
                VStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Text("Credits stored on this device. No refund on delete.")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("AI content varies. Parental guidance advised.")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Button("Restore Purchases") {
                        Task {
                            try? await AppStore.sync()
                            showRestoreMessage = true
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 10)
            }
        }
        .alert("Restore Complete", isPresented: $showRestoreMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Purchases synchronized with Apple. Note: Unused credits are consumables stored locally on this device.")
        }
    }
}
