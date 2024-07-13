import Foundation
import SwiftUI

public class WrapperScreenCoordinator: ScreenCoordinator {
    public let navigationComponent = ScreenCoordinatorComponent()

    @MainActor
    public init() async {}

    @MainActor
    public init(_ viewCoordinator: ViewCoordinator) async {
        await setViewCoordinator(viewCoordinator)
    }

    @MainActor
    public func setViewCoordinator(_ viewCoordinator: ViewCoordinator) async {
        navigationComponent.childrenCoordinators.append(viewCoordinator)
        navigationComponent.setView(viewCoordinator.getView())
    }

    @MainActor
    public func setPlainView(_ view: some View) async {
        navigationComponent.childrenCoordinators.removeAll()
        navigationComponent.setView(view)
    }

    @MainActor
    public func getCurrentViewCoordinator() async -> ViewCoordinator? {
        navigationComponent.childrenCoordinators.first
    }
}
