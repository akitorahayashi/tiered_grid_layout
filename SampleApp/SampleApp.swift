import SwiftUI

@main
struct SampleApp: App {
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains(LaunchArgument.uiTesting.rawValue) {
                TestContentView()
            } else {
                ContentView()
            }
        }
    }
}
