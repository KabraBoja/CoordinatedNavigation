import SwiftUI
import CoordinatedNavigation

@main
struct CoordinatedNavigationExampleApp: App {

    let mainCoordinator: ViewCoordinator

    init() {
        mainCoordinator = AsyncViewCoordinator(loadingView: SplashScreen()) {
            // Simulate long operation
            try! await Task.sleep(for: .seconds(1))
            let viewCoordinator: ViewCoordinator = await ExampleCase.uiTest.createCoordinator()

            // Timer for debugging purposes: Prints the current tree every 2 seconds.
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [viewCoordinator] _ in
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
    case uiTest
    case exampleA
    case exampleB
    case exampleC
    case exampleD

    @MainActor
    func createCoordinator() async -> ViewCoordinator {
        switch self {
        case .uiTest:
            let stackCoordinator = TestStackCoordinator()
            await stackCoordinator.executeSteps([.pushSequence, .pushScreen])
            return stackCoordinator
        case .exampleA:
            return await DefaultStackCoordinator(sequenceCoordinator: ExampleA.RootSequenceCoordinator())
        case .exampleB:
            return await DefaultStackCoordinator(sequenceCoordinator: ExampleB.RootSequenceCoordinator())
        case .exampleC:
            return await ExampleC.CustomTabBarCoordinator()
        case .exampleD:
            return ExampleD.createACustomTutorialScreenCoordinator { print("Next pressed") }
        }
    }
}
