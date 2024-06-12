import Foundation
import SwiftUI

public class WrapperScreenCoordinator: ScreenCoordinatorEntity {
    public let navigationComponent = ScreenCoordinatorComponent()
    var currentViewEntity: ViewEntity?

    public init() async {}

    public init(_ viewEntity: ViewEntity) async {
        await setViewEntity(viewEntity)
    }

    @MainActor
    public func setViewEntity(_ viewEntity: ViewEntity) async {
        currentViewEntity = viewEntity
        navigationComponent.setView(viewEntity.getView())
    }

    @MainActor
    public func setPlainView(_ view: some View) async {
        currentViewEntity = nil
        navigationComponent.setView(view)
    }

    public func getCurrentViewEntity() -> ViewEntity? {
        currentViewEntity
    }
}
