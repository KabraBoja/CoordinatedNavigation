import SwiftUI
import CoordinatedNavigation

@main
struct CoordinatedNavigationExampleApp: App {

    enum ExampleCase {
        case exampleA
        case exampleB
        case exampleC
        case exampleD
    }

    let exampleCase: ExampleCase = .exampleD

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
                        await ExampleC.CustomTabBarCoordinator()
                    case .exampleD:
                        ExampleD.createACustomTutorialScreenCoordinator {
                            print("Next pressed")
                        }
                    }
                }.value
                return result
            }.getView()
        }
    }
}


