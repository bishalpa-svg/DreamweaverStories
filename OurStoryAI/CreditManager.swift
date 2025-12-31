import SwiftUI
import Combine

@MainActor
class CreditManager: ObservableObject {

    static let shared = CreditManager()
    
    private let serviceName = "com.navivagames.credits"
    private let balanceKey = "userBalance"
    private let welcomeGiftKey = "hasReceivedWelcomeGift_secure" // New secure key

    @Published var currentCredits: Int {
        didSet {
            saveCreditsToKeychain()
        }
    }

    // Now backed by Keychain, not UserDefaults
    var hasReceivedWelcomeGift: Bool {
        get {
            // Read string from keychain, if it exists return true
            return KeychainHelper.shared.read(service: serviceName, account: welcomeGiftKey) != nil
        }
    }

    private init() {
        // 1. Load existing credits from Keychain
        self.currentCredits = CreditManager.loadCreditsFromKeychain()
        
        // 2. Debugging logs
        print("🔍 Debug: Loaded Credits: \(currentCredits)")
        print("🔍 Debug: Has Received Gift? \(hasReceivedWelcomeGift)")

        // 3. Check secure flag
        if !hasReceivedWelcomeGift {
            print("🎁 Truly new user detected. Adding welcome gift...")
            
            // Give the gift
            currentCredits += 1
            
            // Save the new balance
            let balanceData = Data(withUnsafeBytes(of: currentCredits) { Data($0) })
            KeychainHelper.shared.save(balanceData, service: serviceName, account: balanceKey)
            
            // 🛑 MARK AS RECEIVED IN KEYCHAIN
            // We just save a dummy "true" byte. The existence of this item means "True".
            let trueData = Data([1])
            KeychainHelper.shared.save(trueData, service: serviceName, account: welcomeGiftKey)
            
            print("✅ Gift Added & Flag Secured in Keychain.")
        } else {
            print("ℹ️ User has already received welcome gift (persisted across installs).")
        }
    }

    func addCredits(amount: Int) {
        currentCredits += amount
    }

    func canAfford(cost: Int) -> Bool {
        return currentCredits >= cost
    }

    func spendCredits(amount: Int) {
        guard currentCredits >= amount else { return }
        currentCredits -= amount
    }
    
    // MARK: - Security Logic
    
    private func saveCreditsToKeychain() {
        let data = Data(withUnsafeBytes(of: currentCredits) { Data($0) })
        KeychainHelper.shared.save(data, service: serviceName, account: balanceKey)
    }
    
    private static func loadCreditsFromKeychain() -> Int {
        if let data = KeychainHelper.shared.read(service: "com.navivagames.credits", account: "userBalance") {
            let value = data.withUnsafeBytes { $0.load(as: Int.self) }
            return value
        }
        return 0
    }
}
