import ComposableArchitecture
import SwiftUI

@main
struct CodefinityTestTaskApp: App {
    var body: some Scene {
        WindowGroup {
            SummaryView(
                store: Store(initialState: SummaryFeature.State()) {
                    SummaryFeature()
                }
            )
        }
    }
}
