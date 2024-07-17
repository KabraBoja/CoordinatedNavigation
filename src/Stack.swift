import Foundation
import SwiftUI

enum Event {
    case removeCoordinatorsNeeded([CoordinatorID])
    case navigationPathUpdateNeeded
}

enum PathRepresentation {
    case path(String)
    case array([CoordinatorID])
}

public class StackCoordinatorComponent: ObservableObject, ViewComponent {

    @Published var navigationPath: NavigationPath = NavigationPath()
    @Published var sequenceCoordinator: SequenceCoordinator?
    public let navigationId: CoordinatorID = CoordinatorID()
    let presentingComponent: PresentingScreenCoordinatorComponent = PresentingScreenCoordinatorComponent()
    public var tag: String = "STACK"

    private var wasInitialized: Bool = false
    private var updatePathNeeded: Bool = false
//    private var lastOnDisappearPath: String = ""

    public init() {
        self.presentingComponent.setParent(stack: self)
    }

    public init(sequence: SequenceCoordinator) {
        self.sequenceCoordinator = sequence
        self.presentingComponent.setParent(stack: self)
    }

    public func getView() -> AnyView {
        StackCoordinatorComponentView(coordinator: self).toAnyView()
    }

    struct StackCoordinatorComponentView: View {

        @ObservedObject var coordinator: StackCoordinatorComponent

        init(coordinator: StackCoordinatorComponent) {
            self.coordinator = coordinator
        }

        var body: some View {
            PresentingScreenCoordinatorComponent.PresentingView(
                coordinator: coordinator.presentingComponent,
                content: NavigationStack(path: $coordinator.navigationPath) {
                    if coordinator.sequenceCoordinator != nil, let firstView = coordinator.getFirstCoordinatorView() {
                        firstView.navigationDestination(for: UUID.self) { item in
                            coordinator.getCoordinatorView(item).onDisappear {
                                Task { @MainActor in
                                    // Trying optimization
                                    //                                    let tree = NavigationStackTree.getTreeRecursive(from: NavigationStackTree.Node(coordinator))
                                    //try! await Task.sleep(for: .microseconds(10))
                                    let path = coordinator.navigationPath.getPathRepresentation()
                                    //if path != coordinator.lastOnDisappearPath {
                                    //                                        coordinator.lastOnDisappearPath = path
                                    await coordinator.removeUnusedCoordinators(path: path)
                                    //}
                                }
                            }
                        }
                    }
                }.task {
                    if !coordinator.wasInitialized {
                        coordinator.wasInitialized = true
                        coordinator.scheduleUpdatePath()
                    }
                }
            )
        }
    }

    @MainActor
    public func set(sequence: SequenceCoordinator) async {
        await pop()
        sequence.navigationComponent.parent = SequenceCoordinatorComponent.Parent(stack: self)
        sequenceCoordinator = sequence
        scheduleUpdatePath()
    }

    @MainActor
    public func pop() async {
        await sequenceCoordinator?.navigationComponent.destroyComponent()
        sequenceCoordinator = nil
        scheduleUpdatePath()
    }

    func scheduleUpdatePath() {
        Task { @MainActor in
            updatePathNeeded = true
            if self.wasInitialized {
                try? await Task.sleep(for: .milliseconds(1)) // We want to trigger the update with a dispatch async.
                if updatePathNeeded {
                    let arrayOfId: [CoordinatorID] = NavigationStackTree.getIDTreeRecursive(from: NavigationStackTree.Node(self))
                    let withoutFirst = arrayOfId.dropFirst()
                    self.navigationPath = NavigationPath(withoutFirst)
                    updatePathNeeded = false
                }
            }
        }
    }

    @MainActor
    func eventReceived(event: Event) async {
        switch event {
        case .navigationPathUpdateNeeded:
            scheduleUpdatePath()
        case .removeCoordinatorsNeeded(let coordinatorsIDs):
            await removeCoordinators(iDs: coordinatorsIDs)
        }
    }

    @MainActor
    private func removeCoordinators(iDs: [CoordinatorID]) async {
        guard let sequenceCoordinator = sequenceCoordinator else { return }
        if await sequenceCoordinator.navigationComponent.removeCoordinators(iDs: iDs) {
            await pop()
        }
    }

    @MainActor
    private func removeUnusedCoordinators(path: String) async {
        guard let sequenceCoordinator = sequenceCoordinator else { return }

        var pathAddingFirst: String = path
        if let firstId = NavigationStackTree.getFirstComponent(from: NavigationStackTree.Node(self))?.navigationId {
            pathAddingFirst.append(firstId.uuidString)
        }

        let childInPath = await sequenceCoordinator.navigationComponent.removeUnusedCoordinators(path: pathAddingFirst)
        if !childInPath {
            self.sequenceCoordinator = nil
        }
    }

    private func getCoordinatorView(_ id: UUID) -> AnyView? {
        if let coordinator = NavigationStackTree.getComponent(from: NavigationStackTree.Node(self), navigationId: id),
           let screenCoordinator = coordinator as? ScreenCoordinatorComponent {
            return screenCoordinator.getView()
        }
        return nil
    }

    private func getFirstCoordinatorView() -> AnyView? {
        if let coordinator = NavigationStackTree.getFirstComponent(from: NavigationStackTree.Node(self)),
           let screenCoordinator = coordinator as? ScreenCoordinatorComponent {
            return screenCoordinator.getView()
        }
        return nil
    }

    @MainActor
    public func getPresentingComponent() async -> PresentingScreenCoordinatorComponent {
        presentingComponent
    }

    @MainActor
    func destroyComponent() async {
        await pop()
    }

    public func currentRoutes() -> [Tree.Route] {
        var routes: [Tree.Route] = []
        if let presentedCoordinator = presentingComponent.presentedCoordinator {
            let transition = switch presentingComponent.presentationMode {
            case .fullscreen: Tree.Route.Transition.fullscreen
            case .sheet: Tree.Route.Transition.sheet
            }
            routes.append(Tree.Route(coordinator: presentedCoordinator.getCoordinator(), transition: transition))
        }
        if let sequenceCoordinator = sequenceCoordinator {
            routes.append(Tree.Route(coordinator: sequenceCoordinator, transition: .stackRoot))
        }
        return routes
    }
}

public class DefaultStackCoordinator: StackCoordinator {
    public let navigationComponent: StackCoordinatorComponent = StackCoordinatorComponent()

    public init() {}

    public init(sequenceCoordinator: SequenceCoordinator) async {
        await navigationComponent.set(sequence: sequenceCoordinator)
    }
}
