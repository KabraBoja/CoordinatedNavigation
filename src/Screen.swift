import Foundation
import SwiftUI

public class ScreenCoordinatorComponent: ObservableObject, ViewComponent {
    public let navigationId: CoordinatorID = CoordinatorID()
    public var tag: String = "SCREEN"
    public var children: [any Entity] {
        if let presentingComponent = presentingComponent, let presentedEntity = presentingComponent.presentedEntity {
            return [presentedEntity.getEntity()]
        } else {
            return []
        }
    }

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

    @MainActor
    func destroyComponent() async {
        //print("Screen destroyed")
        presentingComponent = nil
        view = nil
    }
}

public class DefaultScreenCoordinator: ScreenCoordinatorEntity {
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
