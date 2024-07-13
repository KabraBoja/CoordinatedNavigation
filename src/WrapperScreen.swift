import Foundation
import SwiftUI

public class WrapperScreenCoordinator: ScreenCoordinatorEntity {
    public let navigationComponent = ScreenCoordinatorComponent()

    public init() async {}

    public init(_ viewEntity: ViewEntity) async {
        await setViewEntity(viewEntity)
    }

    @MainActor
    public func setViewEntity(_ viewEntity: ViewEntity) async {
        navigationComponent.childrenEntities.append(viewEntity)
        navigationComponent.setView(viewEntity.getView())
    }

    @MainActor
    public func setPlainView(_ view: some View) async {
        navigationComponent.childrenEntities.removeAll()
        navigationComponent.setView(view)
    }

    public func getCurrentViewEntity() -> ViewEntity? {
        navigationComponent.childrenEntities.first
    }
}
