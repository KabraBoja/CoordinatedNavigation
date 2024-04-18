import Foundation
import SwiftUI
import CoordinatedNavigation

class SimpleTitleScreenCoordinator: ScreenCoordinatorEntity {
    let navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()

    init(title: String) {
        navigationComponent.setView(Text(title).navigationTitle(title))
    }
}

class CustomScreenCoordinator: ScreenCoordinatorEntity, ObservableObject {

    let navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()

    @Published var actions: [Action]
    @Published var title: String
    @Published var isBackAllowed: Bool

    struct Action: Identifiable {
        let id: String
        let closure: () async -> Void
    }

    init(title: String, actions: [Action], isBackAllowed: Bool) {
        self.actions = actions
        self.title = title
        self.isBackAllowed = isBackAllowed
        navigationComponent.setView(ActionsView(coordinator: self))
    }

    struct ActionsView: View {
        @ObservedObject var coordinator: CustomScreenCoordinator

        var body: some View {
            VStack {
                Text(coordinator.title)
                Text("Actions")
                ForEach(coordinator.actions) { action in
                    Button(action: {
                        Task { await action.closure() }
                    }, label: {
                        Text(action.id)
                    })
                }
            }
            .navigationTitle(coordinator.title)
            .navigationBarBackButtonHidden(!coordinator.isBackAllowed)
        }
    }
}
