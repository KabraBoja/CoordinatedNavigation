import Foundation
import SwiftUI

public class ScreenCoordinatorComponent: ObservableObject, ViewComponent {
    public let navigationId: CoordinatorID = CoordinatorID()
    public var tag: String = "SCREEN"

    @Published var view: AnyView?
    @Published var presentingComponent: PresentingScreenCoordinatorComponent?
    @Published private var wasInitialized: Bool = false

    public init() {}

    public init(view: some View) {
        self.view = view.toAnyView()
    }

    public func getView() -> AnyView {
        ContentView(coordinator: self).toAnyView()
    }

    public func setView(_ view: some View) {
        self.view = view.toAnyView()
    }

    @MainActor
    public func getPresentingComponent() async -> PresentingScreenCoordinatorComponent {
        if let presentingComponent = presentingComponent {
            return presentingComponent
        } else {
            let presentingComponent = PresentingScreenCoordinatorComponent()
            presentingComponent.setParent(screen: self)
            self.presentingComponent = presentingComponent
            return presentingComponent
        }
    }

    struct ContentView: View {
        @ObservedObject var coordinator: ScreenCoordinatorComponent

        var body: some View {
            if coordinator.wasInitialized, let presentingComponent = coordinator.presentingComponent {
                PresentingScreenCoordinatorComponent.PresentingView(coordinator: presentingComponent, content: getView())
            } else {
                getView().task {
                    coordinator.wasInitialized = true
                }
            }
        }

        func getView() -> AnyView {
            if let view = coordinator.view {
                view
            } else {
                EmptyView().toAnyView()
            }
        }
    }

    public func currentRoutes() -> [Tree.Route] {
        var routes: [Tree.Route] = []
        if let presentingComponent = presentingComponent, let presentedCoordinator = presentingComponent.presentedCoordinator {
            let transition = switch presentingComponent.presentationMode {
            case .fullscreen: Tree.Route.Transition.fullscreen
            case .sheet: Tree.Route.Transition.sheet
            }
            routes.append(Tree.Route(coordinator: presentedCoordinator.getCoordinator(), transition: transition))
        } else {
            routes.append(contentsOf: childrenCoordinators.map { Tree.Route(coordinator: $0, transition: .subview) })
        }
        return routes
    }

    /// Used only for custom screen views that contain childrenEntities. This allows the library to calculate the entire Tree Structure when using custom screen coordinators.
    public var childrenCoordinators: [ViewCoordinator] = []

    @MainActor
    func destroyComponent() async {
        //print("Screen destroyed")
        childrenCoordinators = []
        presentingComponent = nil
        view = nil
    }
}

public class DefaultScreenCoordinator: ScreenCoordinator {
    public let navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()
    public let storage: Any? // Use this property to hold a presenter or any other instance owned by the coordinator

    public init() {
        self.storage = nil
    }

    public init(view: some View) {
        navigationComponent.setView(view)
        self.storage = nil
    }

    public init(storage: Any) {
        self.storage = storage
    }

    public init(view: some View, storage: Any) {
        navigationComponent.setView(view)
        self.storage = storage
    }
}
