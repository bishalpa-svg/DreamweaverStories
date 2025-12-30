import SwiftUI
import Combine // <--- This fixes the "autoconnect" error

struct AILoadingView: View {
    // These match what AppViews is sending now:
    let imageURLString: String?
    let isActive: Bool
    
    @State private var loadingMessage: String = "Preparing canvas..."
    @State private var loadedImage: UIImage? = nil
    
    // Timer to cycle text messages
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    let messages = [
        "Analyzing hero profile...",
        "Sketching the outline...",
        "Mixing the paints...",
        "Adding magical details...",
        "Almost done..."
    ]
    @State private var messageIndex = 0
    
    var body: some View {
        ZStack {
            // Background Box
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .shadow(radius: 2)
            
            // LOGIC: If we have a URL and we are NOT waiting anymore, show the image
            if let url = imageURLString, !isActive {
                
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                    case .failure:
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Failed to load image")
                        }
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                
            } else {
                // LOGIC: Otherwise, show the spinning loader
                VStack(spacing: 20) {
                    ProgressView() // Spinner
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text(loadingMessage) // Changing text
                        .font(.headline)
                        .foregroundColor(.gray)
                        .animation(.easeInOut, value: loadingMessage)
                        .id("loadingText") // Helps animation stability
                }
            }
        }
        .onReceive(timer) { _ in
            if isActive {
                messageIndex = (messageIndex + 1) % messages.count
                loadingMessage = messages[messageIndex]
            }
        }
    }
}
