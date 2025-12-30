import SwiftUI
import Combine

@MainActor
class CreditManager: ObservableObject {

    static let shared = CreditManager()

    @Published var currentCredits: Int {
        didSet {
            UserDefaults.standard.set(currentCredits, forKey: "userCredits")
        }
    }

    @Published var hasReceivedWelcomeGift: Bool {
        didSet {
            UserDefaults.standard.set(hasReceivedWelcomeGift, forKey: "hasReceivedWelcomeGift")
        }
    }

    private init() {
        self.currentCredits = UserDefaults.standard.integer(forKey: "userCredits")
        self.hasReceivedWelcomeGift = UserDefaults.standard.bool(forKey: "hasReceivedWelcomeGift")

        if !hasReceivedWelcomeGift {
            currentCredits += 1
            hasReceivedWelcomeGift = true
            print("🎁 Welcome Gift Added")
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
}

