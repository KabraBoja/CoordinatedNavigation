import Foundation

public struct Tree {

    public enum Node {
        case branch(route: Route, children: [Node])
        case leaf(route: Route)

        public var route: Route {
            switch self {
            case .branch(let route, _): route
            case .leaf(let route): route
            }
        }
    }

    public struct Route {
        public let coordinator: Coordinator
        public let transition: Transition

        public enum Transition {
            case root
            case stackRoot
            case push
            case sheet
            case fullscreen
            case subview
            case custom(String)

            public var name: String {
                switch self {
                case .root: "ROOT"
                case .stackRoot: "STACK_ROOT"
                case .push: "PUSH"
                case .sheet: "SHEET"
                case .fullscreen: "FULLSCREEN"
                case .subview: "SUBVIEW"
                case .custom(let string): string
                }
            }
        }
    }

    public static func getTree(from: Coordinator) -> Node {
        let routes = from.component.currentRoutes()
        if routes.count > 0 {
            var childrenNodes: [Node] = []
            for route in routes {
                childrenNodes.append(getTreeRecursive(from: route))
            }
            return Node.branch(route: Route(coordinator: from, transition: .root), children: childrenNodes)
        } else {
            return Node.leaf(route: Route(coordinator: from, transition: .root))
        }
    }

    public static func getFlatTree(from: Coordinator) -> [Route] {
        getFlatTree(from: getTree(from: from))
    }

    public static func printTree(from: Coordinator, _ closure: (Node) -> String ) -> String {
        printTree(from: getTree(from: from), closure)
    }

    public static func findRoute(from: Coordinator, navigationId: CoordinatorID) -> Route? {
        let tree = getFlatTree(from: from)
        return tree.first { $0.coordinator.navigationId == navigationId }
    }

    public static func findRoute(from: Coordinator, tag: String) -> Route? {
        let tree = getFlatTree(from: from)
        return tree.first { $0.coordinator.component.tag == tag }
    }

    public static func findAllRoutes(from: Coordinator, tag: String) -> [Route] {
        let tree = getFlatTree(from: from)
        return tree.filter { $0.coordinator.component.tag == tag }
    }

    public static func findCoordinator(from: Coordinator, navigationId: CoordinatorID) -> Coordinator? {
        findRoute(from: from, navigationId: navigationId)?.coordinator
    }

    public static func findCoordinator(from: Coordinator, tag: String) -> Coordinator? {
        findRoute(from: from, tag: tag)?.coordinator
    }

    public static func findAllCoordinators(from: Coordinator, tag: String) -> [Coordinator] {
        findAllRoutes(from: from, tag: tag).map{ $0.coordinator }
    }

    public static func findScreenCoordinator(from: Coordinator, tag: String) -> ScreenCoordinator? {
        let tree = getFlatTree(from: from)
        return tree.compactMap { $0.coordinator as? ScreenCoordinator }.filter { $0.component.tag == tag }.first
    }

    public static func findScreenCoordinator(from: Coordinator, id: CoordinatorID) -> ScreenCoordinator? {
        let tree = getFlatTree(from: from)
        return tree.compactMap { $0.coordinator as? ScreenCoordinator }.filter { $0.navigationId == id }.first
    }

    public static func findSequenceCoordinator(from: Coordinator, tag: String) -> SequenceCoordinator? {
        let tree = getFlatTree(from: from)
        return tree.compactMap { $0.coordinator as? SequenceCoordinator }.filter { $0.component.tag == tag }.first
    }

    public static func findSequenceCoordinator(from: Coordinator, id: CoordinatorID) -> SequenceCoordinator? {
        let tree = getFlatTree(from: from)
        return tree.compactMap { $0.coordinator as? SequenceCoordinator }.filter { $0.navigationId == id }.first
    }

    public static func findStackCoordinator(from: Coordinator, tag: String) -> StackCoordinator? {
        let tree = getFlatTree(from: from)
        return tree.compactMap { $0.coordinator as? StackCoordinator }.filter { $0.component.tag == tag }.first
    }

    public static func findStackCoordinator(from: Coordinator, id: CoordinatorID) -> StackCoordinator? {
        let tree = getFlatTree(from: from)
        return tree.compactMap { $0.coordinator as? StackCoordinator }.filter { $0.navigationId == id }.first
    }

    public static func reduceTree<T>(from: Node, _ initialResult: T, _ nextPartialResult: (T, Node) -> T ) -> T {
        switch from {
        case .branch(_, let children):
            var result: T = nextPartialResult(initialResult, from)
            for child in children {
                result = reduceTree(from: child, result, nextPartialResult)
            }
            return result
        case .leaf(let route):
            return nextPartialResult(initialResult, from)
        }
    }

    static func printTree(from: Node, _ closure: (Node) -> String ) -> String {
        switch from {
        case .branch(_, let children):
            var string = "\(closure(from))"
            for index in 0 ..< children.count {

                if index == 0 {
                    string = string + ": ["
                }
                string = string + "\(printTree(from: children[index], closure))"

                if index < children.count - 1 {
                    string = string + ", "
                }

                if index == children.count - 1 {
                    string = string + "]"
                }
            }
            return string
        case .leaf(let route):
            return "\(closure(from))"
        }
    }

    static func getTreeRecursive(from: Route) -> Node {
        let routes = from.coordinator.component.currentRoutes()
        if routes.count > 0 {
            var childrenNodes: [Node] = []
            for route in routes {
                childrenNodes.append(getTreeRecursive(from: route))
            }
            return Node.branch(route: Route(coordinator: from.coordinator, transition: from.transition), children: childrenNodes)
        } else {
            return Node.leaf(route: Route(coordinator: from.coordinator, transition: from.transition))
        }
    }

    static func getFlatTree(from: Node) -> [Route] {
        switch from {
        case .branch(let route, let children):
            var flatTree: [Route] = [route]
            for child in children {
                flatTree.append(contentsOf: getFlatTree(from: child))
            }
            return flatTree
        case .leaf(let route):
            return [route]
        }
    }

}
