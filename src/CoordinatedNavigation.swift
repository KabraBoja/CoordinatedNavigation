import Foundation
import SwiftUI

public typealias CoordinatorID = UUID

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

public protocol Coordinator {
    var navigationId: CoordinatorID { get }
    var component: Component { get }
}

public protocol SequenceableCoordinator: Coordinator {}

public protocol ViewCoordinator: Coordinator {
    func getView() -> AnyView
}

public protocol StackCoordinator: AnyObject, ViewCoordinator {
    var navigationComponent: StackCoordinatorComponent { get }
}

public protocol SequenceCoordinator: AnyObject, SequenceableCoordinator {
    var navigationComponent: SequenceCoordinatorComponent { get }
}

public protocol ScreenCoordinator: AnyObject, ViewCoordinator, SequenceableCoordinator {
    var navigationComponent: ScreenCoordinatorComponent { get }
}

public extension StackCoordinator {
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

public extension SequenceCoordinator {
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

public extension ScreenCoordinator {
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

public extension Coordinator {
    var component: Component {
        if let stackCoordinator = self as? StackCoordinator {
            return stackCoordinator.navigationComponent
        } else if let sequenceCoordinator = self as? SequenceCoordinator {
            return sequenceCoordinator.navigationComponent
        } else if let screenCoordinator = self as? ScreenCoordinator {
            return screenCoordinator.navigationComponent
        } else {
            fatalError("Unknown Coordinator Class Node")
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

    public func toScreenCoordinator() -> ScreenCoordinator {
        DefaultScreenCoordinator(view: self)
    }
}
