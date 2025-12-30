import SwiftUI

@main
struct OurStoryAIApp: App {
    
    var body: some Scene {
        WindowGroup {
            // We changed this from 'ContentView' to 'AppViews'
            // We also removed the 'NavigationStack' here because AppViews handles that internally now.
            AppViews()
        }
    }
}
