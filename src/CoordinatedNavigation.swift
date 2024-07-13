import Foundation
import SwiftUI

public typealias CoordinatorID = UUID

public struct Route {
    public let entity: Entity
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

public protocol Component {
    var navigationId: CoordinatorID { get }

    /// Component name
    var tag: String { get set }

    /// Current routes shown in the hierarchy
    func currentRoutes() -> [Route]
}

public protocol ViewComponent: Component {
    func getView() -> AnyView
}

public protocol Entity {
    var navigationId: CoordinatorID { get }
    var component: Component { get }
}

public protocol SequenceableEntity: Entity {}

public protocol ViewEntity: Entity {
    func getView() -> AnyView
}

public protocol StackCoordinatorEntity: AnyObject, ViewEntity {
    var navigationComponent: StackCoordinatorComponent { get }
}

public protocol SequenceCoordinatorEntity: AnyObject, SequenceableEntity {
    var navigationComponent: SequenceCoordinatorComponent { get }
}

public protocol ScreenCoordinatorEntity: AnyObject, ViewEntity, SequenceableEntity {
    var navigationComponent: ScreenCoordinatorComponent { get }
}

public extension StackCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }

    func getView() -> AnyView {
        navigationComponent.getView()
    }

    var tag: String {
        get {
            navigationComponent.tag
        }
        set {
            navigationComponent.tag = newValue
        }
    }
}

public extension SequenceCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }

    var tag: String {
        get {
            navigationComponent.tag
        }
        set {
            navigationComponent.tag = newValue
        }
    }
}

public extension ScreenCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }

    func getView() -> AnyView {
        navigationComponent.getView()
    }

    var tag: String {
        get {
            navigationComponent.tag
        }
        set {
            navigationComponent.tag = newValue
        }
    }
}

public extension Entity {
    var component: Component {
        if let stackCoordinator = self as? StackCoordinatorEntity {
            return stackCoordinator.navigationComponent
        } else if let sequenceCoordinator = self as? SequenceCoordinatorEntity {
            return sequenceCoordinator.navigationComponent
        } else if let screenCoordinator = self as? ScreenCoordinatorEntity {
            return screenCoordinator.navigationComponent
        } else {
            fatalError("Unknown Coordinator Entity Node")
        }
    }
}

public extension NavigationPath {
    func getPathRepresentation() -> String {
        if let codable = self.codable,
           let data = try? JSONEncoder().encode(codable) {
            return String(decoding: data, as: UTF8.self)
        } else {
            return ""
        }
    }
}

public extension View {
    public func toAnyView() -> AnyView {
        AnyView(self)
    }

    public func toScreenCoordinator() -> ScreenCoordinatorEntity {
        DefaultScreenCoordinator(view: self)
    }
}
