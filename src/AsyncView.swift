import Foundation
import SwiftUI

/// Use this coordinator to initialize a ViewEntity using async/await.
public class AsyncViewCoordinator<LoadingView: View>: ScreenCoordinatorEntity, ObservableObject {
    public var navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()

    @Published var loadedCoordinator: ViewEntity?
    @Published var loadingView: LoadingView?

    public init(loadingView: LoadingView, closure: @escaping () async -> ViewEntity) {
        self.loadingView = loadingView
        Task { @MainActor in
            let coordinator = await closure()
            self.loadedCoordinator = coordinator
            navigationComponent.childrenEntities.append(coordinator)
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

