import SwiftUI
import CoordinatedNavigation

@main
struct CoordinatedNavigationExampleApp: App {

    enum ExampleCase {
        case exampleA
        case exampleB
    }

    let exampleCase: ExampleCase = .exampleB

    let stackCoordinator: StackCoordinatorEntity

    init() {
        switch exampleCase {
        case .exampleA:
            stackCoordinator = ExampleA.RootStackCoordinator()
        case .exampleB:
            stackCoordinator = ExampleB.RootStackCoordinator()
        }
    }

    var body: some Scene {
        WindowGroup {
            stackCoordinator.getView()
        }
    }
}
