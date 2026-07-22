import SwiftUI

@MainActor
struct AppRootView: View {
    @State private var launchCoordinator = AppLaunchCoordinator()

    var body: some View {
        ZStack {
            switch launchCoordinator.route {
            case .loading:
                FeatherwindLoadingView()
                    .transition(.opacity)
            case .noInternet(let message):
                FeatherwindNoInternetView(message: message) {
                    launchCoordinator.retry()
                }
                .transition(.opacity)
            case .fanContent:
                ContentView()
                    .transition(.opacity)
                    .onAppear {
                        AppDelegate.lockGameOrientation()
                    }
                    .onDisappear {
                        AppDelegate.restoreDefaultOrientations()
                    }
            case .notificationPrompt:
                FeatherwindNotificationOptInView(
                    allowAction: {
                        launchCoordinator.acceptNotifications()
                    },
                    skipAction: {
                        launchCoordinator.skipNotifications()
                    }
                )
                .transition(.opacity)
            case .webView(let request):
                FeatherwindWebView(url: request.url, requestID: request.id)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .preferredColorScheme(.dark)
            }
        }
        .task {
            AppDelegate.startAppsFlyerForLaunch()
            await launchCoordinator.start()
        }
    }
}

#Preview {
    AppRootView()
}
