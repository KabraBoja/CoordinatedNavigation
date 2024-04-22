import Foundation
import SwiftUI
import CoordinatedNavigation

class DebugPrinter {
    static var initCount: Int = 0
    static var bodyCount: Int = 0
    static var printerAttached: Bool = false
}

class SimpleTitleScreenCoordinator: ScreenCoordinatorEntity {
    let navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()

    init(title: String) {
        navigationComponent.setView(SimpleView(title: title))
    }

    struct SimpleView: View {

        let title: String

        init(title: String) {
            DebugPrinter.initCount += 1
            self.title = title
        }

        var body: some View {
            bodyCall()
        }

        func bodyCall() -> some View {
            DebugPrinter.bodyCount += 1
            return Text(title).navigationTitle(title)
        }
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

        if !DebugPrinter.printerAttached {
            DebugPrinter.printerAttached = true
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                print("Init call count: \(DebugPrinter.initCount), body call count: \(DebugPrinter.bodyCount)")
            }
        }

        self.actions = actions
        self.title = title
        self.isBackAllowed = isBackAllowed
        navigationComponent.setView(ActionsView(coordinator: self))
    }

    struct ActionsView: View {
        @ObservedObject var coordinator: CustomScreenCoordinator

        init(coordinator: CustomScreenCoordinator) {
            DebugPrinter.initCount += 1
            self.coordinator = coordinator
        }

        var body: some View {
            bodyCall()
        }

        func bodyCall() -> some View {
            DebugPrinter.bodyCount += 1
            return VStack {
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

struct SplashScreen: View {
    var body: some View {
        VStack {
            Text("Example A")
            Text("Splash Screen")
            ProgressView()
        }
    }
}
