import Foundation
import SwiftUI

public class SequenceCoordinatorComponent: ObservableObject, Component {

    public enum ChildCoordinator {
        case sequence(SequenceCoordinator)
        case screen(ScreenCoordinator)

        public func getID() -> CoordinatorID {
            switch self {
            case .sequence(let coordinator): coordinator.navigationId
            case .screen(let coordinator): coordinator.navigationId
            }
        }

        public func getCoordinator() -> Coordinator {
            switch self {
            case .sequence(let coordinator): coordinator
            case .screen(let coordinator): coordinator
            }
        }
    }

    struct Parent {
        weak var stack: StackCoordinatorComponent?
        weak var sequence: SequenceCoordinatorComponent?

        init(stack: StackCoordinatorComponent?) {
            self.stack = stack
            self.sequence = nil
        }

        init(sequence: SequenceCoordinatorComponent?) {
            self.stack = nil
            self.sequence = sequence
        }
    }

    public let navigationId: CoordinatorID = CoordinatorID()
    public var tag: String = "SEQUENCE"
    var parent: Parent?
    var childCoordinators: [ChildCoordinator] = []

    public func currentRoutes() -> [Route] {
        childCoordinators.map { child in
            Route(coordinator: child.getCoordinator(), transition: .push)
        }
    }

    public init() {
        self.childCoordinators = []
    }

    public init(coordinators: [ChildCoordinator]) {
        self.childCoordinators = coordinators
    }

    @MainActor
    public func push(screen: ScreenCoordinator) async {
        childCoordinators.append(.screen(screen))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func push(screens: [ScreenCoordinator]) async {
        for screen in screens {
            childCoordinators.append(.screen(screen))
        }
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func push(sequence: SequenceCoordinator) async {
        sequence.navigationComponent.parent = Parent(sequence: self)
        childCoordinators.append(.sequence(sequence))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func push(children: [ChildCoordinator]) async {
        for child in children {
            switch child {
            case .screen(let screen):
                childCoordinators.append(.screen(screen))
            case .sequence(let sequence):
                sequence.navigationComponent.parent = Parent(sequence: self)
                childCoordinators.append(.sequence(sequence))
            }
        }
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func pop(count: Int = 1) async {
        let dropCount = childCoordinators.count - count
        guard dropCount > 0 else { return }
        let removedCoordinatorIDs = childCoordinators.dropFirst(dropCount).map { $0.getID() }
        await sendEventToParent(event: .removeCoordinatorsNeeded(removedCoordinatorIDs))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func popToFirst() async {
        let count = childCoordinators.count - 1
        await pop(count: count)
    }

    @MainActor
    public func pop(id: CoordinatorID) async {
        guard childCoordinators.contains(where: { $0.getID() == id }) else { return }
        await sendEventToParent(event: .removeCoordinatorsNeeded([id]))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func pop(sequence: SequenceCoordinator) async {
        await pop(id: sequence.navigationId)
    }

    @MainActor
    public func pop(screen: ScreenCoordinator) async {
        await pop(id: screen.navigationId)
    }

    @MainActor
    public func set(screen: ScreenCoordinator) async {
        await set(screens: [screen])
    }

    @MainActor
    public func set(screens: [ScreenCoordinator]) async {
        let removedCoordinatorIDs = childCoordinators.map { $0.getID() }
        for screen in screens {
            childCoordinators.append(.screen(screen))
        }
        await sendEventToParent(event: .removeCoordinatorsNeeded(removedCoordinatorIDs))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func set(sequence: SequenceCoordinator) async {
        sequence.navigationComponent.parent = Parent(sequence: self)
        let removedCoordinatorIDs = childCoordinators.map { $0.getID() }
        childCoordinators.append(.sequence(sequence))
        await sendEventToParent(event: .removeCoordinatorsNeeded(removedCoordinatorIDs))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func set(children: [ChildCoordinator]) async {
        let removedCoordinatorIDs = childCoordinators.map { $0.getID() }
        for child in children {
            switch child {
            case .screen(let screen):
                childCoordinators.append(.screen(screen))
            case .sequence(let sequence):
                sequence.navigationComponent.parent = Parent(sequence: self)
                childCoordinators.append(.sequence(sequence))
            }
        }
        await sendEventToParent(event: .removeCoordinatorsNeeded(removedCoordinatorIDs))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    public func count() -> Int {
        childCoordinators.count
    }

    public func getChildrenIDs() -> [CoordinatorID] {
        childCoordinators.map { $0.getID() }
    }

    public func getChildren() -> [ChildCoordinator] {
        childCoordinators
    }

    /// Removes the unused children coordinators that are not in the path recursively.
    ///
    /// Returns true if the coordinator still contains at least one child in the path
    @MainActor
    func removeUnusedCoordinators(path: String) async -> Bool {
        var idx = childCoordinators.count
        var childInPath = false
        while idx > 0 {
            var currentChildInPath = false
            let coordinator = childCoordinators[idx - 1]

            switch coordinator {
            case .screen(let screenCoordinator):
                if path.range(of: screenCoordinator.navigationId.uuidString) != nil {
                    currentChildInPath = true
                }

                if currentChildInPath {
                    childInPath = true
                } else {
                    removeCoordinator(id: screenCoordinator.navigationId)
                    await screenCoordinator.navigationComponent.destroyComponent()
                }
            case .sequence(let sequenceCoordinator):
                if await sequenceCoordinator.navigationComponent.removeUnusedCoordinators(path: path) {
                    currentChildInPath = true
                }

                if currentChildInPath {
                    childInPath = true
                } else {
                    removeCoordinator(id: sequenceCoordinator.navigationId)
                    await sequenceCoordinator.navigationComponent.destroyComponent()
                }
            }
            idx = idx - 1
        }
        return childInPath
    }

    /// Removes specified children coordinators recursively
    ///
    /// Returns true if the coordinator still contains at least one child in the path
    @MainActor
    func removeCoordinators(iDs: [CoordinatorID]) async -> Bool {
        var idx = childCoordinators.count
        var allChildrenAreDestroyed = true
        while idx > 0 {
            let coordinator = childCoordinators[idx - 1]
            switch coordinator {
            case .screen(let screenCoordinator):
                if iDs.contains(where: { $0 == screenCoordinator.navigationId }) {
                    await screenCoordinator.navigationComponent.destroyComponent()
                    childCoordinators.removeAll(where: { $0.getID() == screenCoordinator.navigationId })
                } else {
                    allChildrenAreDestroyed = false
                }
            case .sequence(let sequenceCoordinator):
                let sequenceFound = iDs.contains(where: { $0 == sequenceCoordinator.navigationId })
                let sequenceWithoutChildren = await sequenceCoordinator.navigationComponent.removeCoordinators(iDs: iDs)

                if sequenceFound || sequenceWithoutChildren {
                    await sequenceCoordinator.navigationComponent.destroyComponent()
                    childCoordinators.removeAll(where: { $0.getID() == sequenceCoordinator.navigationId })
                } else {
                    allChildrenAreDestroyed = false
                }
            }
            idx = idx - 1
        }
        return allChildrenAreDestroyed
    }

    @MainActor
    func sendEventToParent(event: Event) async {
        if let parentStack = parent?.stack {
            await parentStack.eventReceived(event: event)
        } else if let parentSequence = parent?.sequence {
            await parentSequence.sendEventToParent(event: event)
        }
    }

    func removeCoordinator(id: CoordinatorID) {
        childCoordinators.removeAll { $0.getID() == id }
    }

    @MainActor
    func destroyComponent() async {
        //        print("Sequence destroyed")
        parent = nil
        for child in childCoordinators {
            switch child {
            case .sequence(let sequenceCoordinator):
                await sequenceCoordinator.navigationComponent.destroyComponent()
            case .screen(let screenCoordinator):
                await screenCoordinator.navigationComponent.destroyComponent()
            }
        }
        childCoordinators = []
    }
}

public class DefaultSequenceCoordinator: SequenceCoordinator {
    public let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

    public init() {}

    public init(screenCoordinator: ScreenCoordinator) async {
        await navigationComponent.set(screen: screenCoordinator)
    }

    public init(screenCoordinators: [ScreenCoordinator]) async {
        await navigationComponent.set(screens: screenCoordinators)
    }

    public init(sequenceCoordinator: SequenceCoordinator) async {
        await navigationComponent.set(sequence: sequenceCoordinator)
    }
}
