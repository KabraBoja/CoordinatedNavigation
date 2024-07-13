import Foundation

public struct Tree {
    public static func getTreeRecursive(from: Coordinator) -> [Route] {
        var tree: [Route] = []
        tree.append(Route(coordinator: from, transition: Route.Transition.root))
        for route in from.component.currentRoutes() {
            tree.append(contentsOf: getTreeRecursive(from: route))
        }
        return tree
    }

    public static func findRoute(from: Coordinator, navigationId: CoordinatorID) -> Route? {
        let tree = getTreeRecursive(from: from)
        return tree.first { $0.coordinator.navigationId == navigationId }
    }

    public static func findRoute(from: Coordinator, tag: String) -> Route? {
        let tree = getTreeRecursive(from: from)
        return tree.first { $0.coordinator.component.tag == tag }
    }

    public static func findAllRoutes(from: Coordinator, tag: String) -> [Route] {
        let tree = getTreeRecursive(from: from)
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

    public static func findCoordinator<T: Coordinator>(from: Coordinator, tag: String, type: T.Type) -> T? {
        let tree = getTreeRecursive(from: from)
        return tree.compactMap { $0.coordinator as? T }.filter { $0.component.tag == tag }.first
    }

    public static func findAllCoordinators<T: Coordinator>(from: Coordinator, tag: String, type: T.Type) -> [T] {
        let tree = getTreeRecursive(from: from)
        return tree.compactMap { $0.coordinator as? T }.filter { $0.component.tag == tag }
    }

    static func getTreeRecursive(from: Route) -> [Route] {
        var tree: [Route] = []
        tree.append(from)
        for route in from.coordinator.component.currentRoutes() {
            tree.append(contentsOf: getTreeRecursive(from: route))
        }
        return tree
    }
}
