import Foundation

public struct Tree {
    public enum Node {
        case stack(StackCoordinatorEntity)
        case sequence(SequenceCoordinatorEntity)
        case screen(ScreenCoordinatorEntity)

        public init(_ entity: Entity) {
            if let stackCoordinator = entity as? StackCoordinatorEntity {
                self = .stack(stackCoordinator)
            } else if let sequenceCoordinator = entity as? SequenceCoordinatorEntity {
                self = .sequence(sequenceCoordinator)
            } else if let screenCoordinator = entity as? ScreenCoordinatorEntity {
                self = .screen(screenCoordinator)
            } else {
                fatalError("Unknown Coordinator Entity Node")
            }
        }

        public var component: Component {
            switch self {
            case .stack(let entity):
                entity.navigationComponent
            case .sequence(let entity):
                entity.navigationComponent
            case .screen(let entity):
                entity.navigationComponent
            }
        }

        public var entity: Entity {
            switch self {
            case .stack(let entity):
                entity
            case .sequence(let entity):
                entity
            case .screen(let entity):
                entity
            }
        }

        public var navigationId: CoordinatorID {
            component.navigationId
        }

        public var children: [Entity] {
            self.component.children
        }
    }

    public static func getTreeRecursive(from: Node) -> [Node] {
        var tree: [Node] = []
        tree.append(Node(from.entity))
        for child in from.children {
            tree.append(contentsOf: getTreeRecursive(from: Node(child)))
        }
        return tree
    }

    public static func getEntity(from: Node, navigationId: CoordinatorID) -> Entity? {
        let tree = getTreeRecursive(from: from)
        return tree.first { $0.navigationId == navigationId }?.entity
    }

    public static func getEntity(from: Node, tag: String) -> Entity? {
        let tree = getTreeRecursive(from: from)
        return tree.first { $0.component.tag == tag }?.entity
    }
}
