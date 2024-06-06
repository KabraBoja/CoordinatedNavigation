import Foundation

public struct NavigationTree {
    public enum Node {
        case stack(StackCoordinatorComponent)
        case sequence(SequenceCoordinatorComponent)
        case screen(ScreenCoordinatorComponent)

        public init(_ component: Component) {
            if let stackCoordinator = component as? StackCoordinatorComponent {
                self = .stack(stackCoordinator)
            } else if let sequenceCoordinator = component as? SequenceCoordinatorComponent {
                self = .sequence(sequenceCoordinator)
            } else if let screenCoordinator = component as? ScreenCoordinatorComponent {
                self = .screen(screenCoordinator)
            } else {
                fatalError("Unknown Coordinator Node")
            }
        }

        public var navigationId: CoordinatorID {
            return switch self {
            case .stack(let component):
                component.navigationId
            case .sequence(let component):
                component.navigationId
            case .screen(let component):
                component.navigationId
            }
        }

        public var component: Component {
            return switch self {
            case .stack(let component):
                component
            case .sequence(let component):
                component
            case .screen(let component):
                component
            }
        }
    }

    static func getTreeRecursive(from: Node) -> [Node] {
        var newTree: [Node] = []
        switch from {
        case .stack(let stack):
            if let sequenceCoordinator = stack.sequenceCoordinator {
                newTree.append(contentsOf: getTreeRecursive(from: Node(sequenceCoordinator.navigationComponent)))
            }
        case .sequence(let sequence):
            for child in sequence.childCoordinators {
                switch child {
                case .sequence(let childSequence):
                    newTree.append(contentsOf: getTreeRecursive(from: Node(childSequence.navigationComponent)))
                case .screen(let screen):
                    newTree.append(Node(screen.navigationComponent))
                }
            }
        case .screen(let screen):
            newTree.append(Node(screen))
        }

        return newTree
    }

    static func getIDTreeRecursive(from: Node) -> [CoordinatorID] {
        let tree = getTreeRecursive(from: from)
        return tree.map { $0.navigationId }
    }

    static func getComponent(from: Node, navigationId: CoordinatorID) -> Component? {
        let tree = getTreeRecursive(from: from)
        return tree.first { $0.navigationId == navigationId }?.component
    }

    static func getFirstComponent(from: Node) -> Component? {
        let tree = getTreeRecursive(from: from)
        return tree.first?.component
    }

    static func getRootStackParent(from: Node) -> StackCoordinatorComponent? {
        switch from {
        case .stack(let stackCoordinatorComponent):
            return stackCoordinatorComponent
        case .sequence(let sequenceCoordinatorComponent):
            if let parent = sequenceCoordinatorComponent.parent {
                if let parentStack = parent.stack {
                    return getRootStackParent(from: Node(parentStack))
                } else if let parentSequence = parent.sequence {
                    return getRootStackParent(from: Node(parentSequence))
                } else {
                    return nil
                }
            } else {
                return nil
            }
        case .screen:
            return nil
        }
    }
}
