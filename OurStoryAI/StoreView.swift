import SwiftUI

struct StoreView: View {
    @ObservedObject var creditManager = CreditManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Dark Background
            Color(hex: "1a1a2e").ignoresSafeArea()
            
            VStack(spacing: 25) {
                
                // Header
                VStack(spacing: 5) {
                    Text("Story Store")
                        .font(.custom("Georgia-Bold", size: 32))
                        .foregroundColor(.white)
                    Text("Unlock your imagination")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 40)
                
                // Current Balance Display
                HStack {
                    VStack(alignment: .leading) {
                        Text("YOUR BALANCE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)
                        
                        HStack(spacing: 5) {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.yellow)
                            Text("\(creditManager.currentCredits)")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Credits")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Divider().background(Color.white.opacity(0.2)).padding(.horizontal)
                
                // Purchase Options (UPDATED FOR TESTING)
                ScrollView {
                    VStack(spacing: 15) {
                        
                        // Option 1: Free Daily
                        ProductRow(
                            title: "Daily Gift",
                            desc: "Get 3 free credits to test the app.",
                            amount: 3,
                            price: "Free", // Safe for App Store (Demo mode)
                            color: .blue
                        ) {
                            creditManager.addCredits(amount: 3)
                            dismiss()
                        }
                        
                        // Option 2: Super Pack
                        ProductRow(
                            title: "Developer Pack",
                            desc: "Load 50 credits for heavy testing.",
                            amount: 50,
                            price: "Free", // Safe for App Store (Demo mode)
                            color: .purple,
                            isPopular: true
                        ) {
                            creditManager.addCredits(amount: 50)
                            dismiss()
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Close Button
                Button(action: { dismiss() }) {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 20)
                }
            }
        }
    }
}

// Helper View for a Store Row
struct ProductRow: View {
    let title: String
    let desc: String
    let amount: Int
    let price: String
    let color: Color
    var isPopular: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(color)
                        .font(.title2)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if isPopular {
                            Text("POPULAR")
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(desc)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                    
                    Text("+ \(amount) Credits")
                        .font(.caption)
                        .bold()
                        .foregroundColor(color)
                }
                
                Spacer()
                
                // Price Button Look
                Text(price)
                    .font(.subheadline)
                    .bold()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPopular ? Color.yellow.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isPopular ? 2 : 1)
            )
        }
    }
}
