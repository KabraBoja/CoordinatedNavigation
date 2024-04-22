import SwiftUI
import CoordinatedNavigation

@main
struct CoordinatedNavigationExampleApp: App {

    enum ExampleCase {
        case exampleA
        case exampleB
        case exampleC
    }

    let exampleCase: ExampleCase = .exampleC

    var body: some Scene {
        WindowGroup {
            AsyncViewCoordinator(loadingView: SplashScreen()) { () -> ViewEntity in
                return switch exampleCase {
                case .exampleA:
                    await DefaultStackCoordinator(sequenceCoordinator: ExampleA.RootSequenceCoordinator())
                case .exampleB:
                    await DefaultStackCoordinator(sequenceCoordinator: ExampleB.RootSequenceCoordinator())
                case .exampleC:
                    await ExampleC.CustomTabBarCoordinator()
                }
            }.getView()
        }
    }
}


