import SwiftUI
import StoreKit

struct StoreView: View {

    @ObservedObject var creditManager = CreditManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) var dismiss

    // ✅ THE FIX: LazyVGrid Columns (2 columns equal width)
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    var body: some View {
        ZStack {
            // Dark Magical Background
            FancyBackground()
            
            // Background Sparkles
            SparkleEffect().opacity(0.3)

            VStack(spacing: 0) {
                
                // MARK: - Header
                VStack(spacing: 15) {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 5) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                            .shadow(color: .orange.opacity(0.5), radius: 10)
                        
                        Text("Story Store")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }

                    // Balance Display
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("\(creditManager.currentCredits)")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text("Credits Available")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .padding(.bottom, 20)
                .padding(.top, 20)

                // MARK: - Scrollable Grid
                ScrollView {
                    if storeManager.products.isEmpty {
                        VStack(spacing: 20) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("Summoning magical bundles...")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 50)
                    } else {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(storeManager.products) { product in
                                StoreProductCard(
                                    product: product,
                                    manager: storeManager
                                ) {
                                    Task { await storeManager.purchase(product) }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                
                // MARK: - Footer
                Button("Restore Purchases") {
                    Task { try? await AppStore.sync() }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 10)
            }
        }
    }
}
