import Foundation

public struct Tree {
    public static func getTreeRecursive(from: Entity) -> [Route] {
        var tree: [Route] = []
        tree.append(Route(entity: from, transition: Route.Transition.root))
        for route in from.component.currentRoutes() {
            tree.append(contentsOf: getTreeRecursive(from: route))
        }
        return tree
    }

    public static func findRoute(from: Entity, navigationId: CoordinatorID) -> Route? {
        let tree = getTreeRecursive(from: from)
        return tree.first { $0.entity.navigationId == navigationId }
    }

    public static func findRoute(from: Entity, tag: String) -> Route? {
        let tree = getTreeRecursive(from: from)
        return tree.first { $0.entity.component.tag == tag }
    }

    public static func findAllRoutes(from: Entity, tag: String) -> [Route] {
        let tree = getTreeRecursive(from: from)
        return tree.filter { $0.entity.component.tag == tag }
    }

    public static func findEntity(from: Entity, navigationId: CoordinatorID) -> Entity? {
        findRoute(from: from, navigationId: navigationId)?.entity
    }

    public static func findEntity(from: Entity, tag: String) -> Entity? {
        findRoute(from: from, tag: tag)?.entity
    }

    public static func findAllEntity(from: Entity, tag: String) -> [Entity] {
        findAllRoutes(from: from, tag: tag).map{ $0.entity }
    }

    static func getTreeRecursive(from: Route) -> [Route] {
        var tree: [Route] = []
        tree.append(from)
        for route in from.entity.component.currentRoutes() {
            tree.append(contentsOf: getTreeRecursive(from: route))
        }
        return tree
    }
}
