import Foundation
import SwiftUI

public typealias CoordinatorID = UUID

public protocol Component {
    var navigationId: CoordinatorID { get }
}

public protocol ViewComponent: Component {
    func getView() -> AnyView
}

public protocol ViewEntity {
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

public protocol SequenceableEntity {}

public extension StackCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }

    func getView() -> AnyView {
        navigationComponent.getView()
    }
}

public extension SequenceCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }
}

public extension ScreenCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }

    func getView() -> AnyView {
        navigationComponent.getView()
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
