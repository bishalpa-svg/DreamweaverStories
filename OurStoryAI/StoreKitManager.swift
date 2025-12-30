import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
class StoreKitManager: ObservableObject {

    static let shared = StoreKitManager()

    @Published var products: [Product] = []

    // Your Product IDs
    private let productIDs: [String] = [
        "com.navivagames.credits.3",
        "com.navivagames.credits.10",
        "com.navivagames.credits.25",
        "com.navivagames.credits.50",
        "com.navivagames.credits.100"
    ]

    init() {
        Task {
            await loadProducts()
            await listenForTransactions()
        }
    }

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            // Sort by price (low to high)
            self.products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("❌ Failed to load products:", error)
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                deliverCredits(for: transaction.productID)
                await transaction.finish()
            default:
                break
            }
        } catch {
            print("❌ Purchase error:", error)
        }
    }

    private func deliverCredits(for productID: String) {
        let credits: Int
        switch productID {
        case "com.navivagames.credits.3": credits = 3
        case "com.navivagames.credits.10": credits = 10
        case "com.navivagames.credits.25": credits = 25
        case "com.navivagames.credits.50": credits = 50
        case "com.navivagames.credits.100": credits = 100
        default: credits = 0
        }

        CreditManager.shared.addCredits(amount: credits)
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? result.payloadValue {
                deliverCredits(for: transaction.productID)
                await transaction.finish()
            }
        }
    }
}

// MARK: - Fancy Marketing Logic
extension StoreKitManager {
    
    // 1. Marketing Names
    func marketingTitle(for productID: String) -> String {
        switch productID {
        case "com.navivagames.credits.3":   return "Starter Spark"
        case "com.navivagames.credits.10":  return "Storyteller"
        case "com.navivagames.credits.25":  return "Author's Bundle"
        case "com.navivagames.credits.50":  return "Novel Pack"
        case "com.navivagames.credits.100": return "Royal Library"
        default: return "Credit Pack"
        }
    }
    
    // 2. ✨ NEW: Catchy Descriptions ✨
    func marketingDescription(for productID: String) -> String {
        switch productID {
        case "com.navivagames.credits.3":
            return "Perfect for a quick short story."
        case "com.navivagames.credits.10":
            return "Enough for a few engaging chapters."
        case "com.navivagames.credits.25":
            return "Best value for serious writers."
        case "com.navivagames.credits.50":
            return "Deep dive into long-form content."
        case "com.navivagames.credits.100":
            return "Ultimate access for endless adventures."
        default:
            return "Unlock more magical stories."
        }
    }
    
    // 3. Custom Gradients
    func cardGradient(for productID: String) -> LinearGradient {
        switch productID {
        case "com.navivagames.credits.3":
            return LinearGradient(colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "com.navivagames.credits.10":
            return LinearGradient(colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "com.navivagames.credits.25":
            return LinearGradient(colors: [Color(hex: "8E2DE2").opacity(0.8), Color(hex: "4A00E0").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "com.navivagames.credits.50":
            return LinearGradient(colors: [Color.orange.opacity(0.7), Color.red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "com.navivagames.credits.100":
            return LinearGradient(colors: [Color(hex: "FFD700").opacity(0.8), Color(hex: "FFA500").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // 4. Badges
    func badge(for productID: String) -> String? {
        switch productID {
        case "com.navivagames.credits.25": return "POPULAR"
        case "com.navivagames.credits.50": return "BEST VALUE"
        case "com.navivagames.credits.100": return "ULTIMATE"
        default: return nil
        }
    }
}
