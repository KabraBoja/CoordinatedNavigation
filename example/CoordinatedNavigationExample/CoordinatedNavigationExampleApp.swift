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

    let exampleCase: ExampleCase = .exampleB

    var body: some Scene {
        WindowGroup {
            AsyncViewCoordinator(loadingView: SplashScreen()) { () -> ViewCoordinator in
                let result: ViewCoordinator = await Task {
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

                // Timer for debugging purposes: Prints the current tree every 2 seconds.
                Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                    let tree = Tree.getTreeRecursive(from: result)
                    print(tree.map { "\($0.transition.name) \($0.coordinator.component.tag)" })
                }

                return result
            }.getView()
        }
    }
}


