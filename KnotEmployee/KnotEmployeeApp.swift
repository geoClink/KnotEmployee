import SwiftUI
import UserNotifications

class KnotAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var store: AppStore?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        store?.registerDeviceToken(token)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        let category = response.notification.request.content.categoryIdentifier
        Task { @MainActor in self.store?.handleNotificationTap(category: category) }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct KnotEmployeeApp: App {
    @UIApplicationDelegateAdaptor(KnotAppDelegate.self) var appDelegate
    @State private var store = AppStore()

    init() {
        let cream = UIColor { t in t.userInterfaceStyle == .dark
            ? UIColor(red: 0x1A/255, green: 0x0E/255, blue: 0x08/255, alpha: 1)
            : UIColor(red: 0xF4/255, green: 0xEC/255, blue: 0xDD/255, alpha: 1) }
        let ink = UIColor { t in t.userInterfaceStyle == .dark
            ? UIColor(red: 0xF2/255, green: 0xE8/255, blue: 0xD8/255, alpha: 1)
            : UIColor(red: 0x2A/255, green: 0x18/255, blue: 0x10/255, alpha: 1) }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = cream
        if let large = UIFont(name: "CormorantGaramond-Medium", size: 36) {
            appearance.largeTitleTextAttributes = [.font: large, .foregroundColor: ink]
        }
        if let inline = UIFont(name: "CormorantGaramond-Medium", size: 20) {
            appearance.titleTextAttributes = [.font: inline, .foregroundColor: ink]
        }
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootGate()
                .environment(\.knotTheme, BakeryCoTheme())
                .environment(store)
                .task { await store.restoreSession() }
                .task { await requestNotificationPermission() }
                .onOpenURL { url in Task { await store.handleDeepLink(url) } }
                .onAppear { appDelegate.store = store }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
        }
    }

    private func requestNotificationPermission() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted {
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        }
    }
}
