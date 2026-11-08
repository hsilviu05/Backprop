import SwiftUI

struct RootView: View {
    @AppStorage(OnboardingAnswers.completedKey) private var hasCompletedOnboarding = false
    @Environment(ContentLibrary.self) private var content

    var body: some View {
        Group {
            if let error = content.loadError {
                ContentUnavailableView(
                    "Lessons failed to load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlow { hasCompletedOnboarding = true }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Learn", systemImage: "graduationcap") { HomeView() }
            Tab("Reading", systemImage: "books.vertical") { ReadingView() }
            Tab("Settings", systemImage: "gearshape") { SettingsView() }
        }
    }
}
