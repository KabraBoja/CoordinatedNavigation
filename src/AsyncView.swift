import Foundation
import SwiftUI

/// Use this coordinator to initialize a ViewCoordinator using async/await.
public class AsyncViewCoordinator<LoadingView: View>: ScreenCoordinator, ObservableObject {
    public var navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()

    @Published var loadedCoordinator: ViewCoordinator?
    @Published var loadingView: LoadingView?

    public init(loadingView: LoadingView, closure: @escaping () async -> ViewCoordinator) {
        self.loadingView = loadingView
        Task { @MainActor in
            let coordinator = await closure()
            self.loadedCoordinator = coordinator
            navigationComponent.childrenCoordinators.append(coordinator)
            self.loadingView = nil
        }
    }

    public func getView() -> AnyView {
        ContentView(coordinator: self).toAnyView()
    }

    struct ContentView: View {
        @ObservedObject var coordinator: AsyncViewCoordinator<LoadingView>

        var body: some View {
            if let loadedCoordinator = coordinator.loadedCoordinator {
                loadedCoordinator.getView()
            } else if let loadingView = coordinator.loadingView {
                loadingView
            }
        }
    }
}

