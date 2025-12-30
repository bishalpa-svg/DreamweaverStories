import Foundation
import SwiftUI
import Combine

class CreditManager: ObservableObject {
    static let shared = CreditManager()
    
    @Published var currentCredits: Int = 0
    
    private let creditsKey = "user_credits_balance"
    private let hasGivenWelcomeKey = "has_given_welcome_credits_v1"
    
    private init() {
        let savedCredits = UserDefaults.standard.integer(forKey: creditsKey)
        self.currentCredits = savedCredits
        
        if !UserDefaults.standard.bool(forKey: hasGivenWelcomeKey) {
            self.currentCredits = 1
            UserDefaults.standard.set(true, forKey: hasGivenWelcomeKey)
            save()
        }
    }
    
    func save() {
        UserDefaults.standard.set(currentCredits, forKey: creditsKey)
    }
    
    // NEW: Check if they have enough for a specific cost
    func canAfford(cost: Int) -> Bool {
        return currentCredits >= cost
    }
    
    // NEW: Spend a specific amount
    func spendCredits(amount: Int) {
        if currentCredits >= amount {
            currentCredits -= amount
            save()
        }
    }
    
    func addCredits(amount: Int) {
        currentCredits += amount
        save()
    }
}
