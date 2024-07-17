import SwiftUI
import CoordinatedNavigation

@main
struct CoordinatedNavigationExampleApp: App {

    let mainCoordinator: ViewCoordinator

    init() {
        mainCoordinator = AsyncViewCoordinator(loadingView: SplashScreen()) { () -> ViewCoordinator in
            // Simulate long operation
            try! await Task.sleep(for: .seconds(1))
            let viewCoordinator: ViewCoordinator = await ExampleCase.exampleB.createCoordinator()

            // Timer for debugging purposes: Prints the current tree every 2 seconds.
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [viewCoordinator] _ in
                let treeString = Tree.printTree(from: viewCoordinator) { node in
                    "\(node.route.transition.name) \(node.route.coordinator.component.tag)"
                }
                print(treeString)
            }

            return viewCoordinator
        }
    }

    var body: some Scene {
        WindowGroup {
            mainCoordinator.getView()
        }
    }
}

enum ExampleCase {
    case exampleA
    case exampleB
    case exampleC
    case exampleD

    @MainActor
    func createCoordinator() async -> ViewCoordinator {
        switch self {
        case .exampleA:
            await DefaultStackCoordinator(sequenceCoordinator: ExampleA.RootSequenceCoordinator())
        case .exampleB:
            await DefaultStackCoordinator(sequenceCoordinator: ExampleB.RootSequenceCoordinator())
        case .exampleC:
            await ExampleC.CustomTabBarCoordinator()
        case .exampleD:
            ExampleD.createACustomTutorialScreenCoordinator { print("Next pressed") }
        }
    }
}
