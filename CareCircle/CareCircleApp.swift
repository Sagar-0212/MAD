import SwiftUI
import FirebaseCore
import FirebaseAuth

// MARK: - App Delegate for Firebase configuration
class CareCircleAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
        } else {
            // Bulletproof fallback ensuring connection to carecircle-6809f even if plist file is unbundled
            let options = FirebaseOptions(googleAppID: "1:249871738260:ios:791298523439eb64c6db81",
                                          gcmSenderID: "249871738260")
            options.apiKey = "AIzaSyAftZnjiGa8ynl158Y6Qcm9-oTOufuu6Jc"
            options.projectID = "carecircle-6809f"
            options.storageBucket = "carecircle-6809f.firebasestorage.app"
            options.bundleID = "com.carecircle.CareCircle"
            FirebaseApp.configure(options: options)
        }
        return true
    }
}

@main
struct CareCircleApp: App {
    @UIApplicationDelegateAdaptor(CareCircleAppDelegate.self) var delegate

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    private func configureAppearance() {
        // Configure standard UIKit appearances to match CareCircle Paper & Ink tokens
        let paperUIColor = UIColor(Color.ccPaper)
        let inkUIColor = UIColor(Color.ccInk)

        // Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = paperUIColor
        navAppearance.titleTextAttributes = [.foregroundColor: inkUIColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: inkUIColor]
        navAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Tab Bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = paperUIColor
        tabAppearance.shadowColor = UIColor(Color.ccHairline)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
