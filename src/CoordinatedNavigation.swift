import Foundation
import SwiftUI

public typealias CoordinatorID = UUID

public protocol Component {
    var navigationId: CoordinatorID { get }

    /// Component name
    var tag: String { get set }

    /// Current children entities shown in the hierarchy
    var children: [Entity] { get }
}

public protocol ViewComponent: Component {
    func getView() -> AnyView
}

public protocol Entity {
    var navigationId: CoordinatorID { get }
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
