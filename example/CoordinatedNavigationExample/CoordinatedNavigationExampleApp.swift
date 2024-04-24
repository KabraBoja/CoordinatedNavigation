import SwiftUI
import CoordinatedNavigation

@main
struct CoordinatedNavigationExampleApp: App {

    enum ExampleCase {
        case exampleA
        case exampleB
        case exampleC
    }

    let exampleCase: ExampleCase = .exampleB

    var body: some Scene {
        WindowGroup {
            AsyncViewCoordinator(loadingView: SplashScreen()) { () -> ViewEntity in
                let result: ViewEntity = await Task {
                    try? await Task.sleep(for: .seconds(1))

                    return switch exampleCase {
                    case .exampleA:
                        await DefaultStackCoordinator(sequenceCoordinator: ExampleA.RootSequenceCoordinator())
                    case .exampleB:
                        await DefaultStackCoordinator(sequenceCoordinator: ExampleB.RootSequenceCoordinator())
                    case .exampleC:
                        DefaultScreenCoordinator(view: ExampleC.TestiOSBugStackInTabView())
                    }
                }.value
                return result
            }.getView()
        }
    }
}


