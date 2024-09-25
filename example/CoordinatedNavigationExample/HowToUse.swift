import Foundation
import SwiftUI
import CoordinatedNavigation

public struct TitleView: View {

    public let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.title)
            .navigationTitle(title)
    }
}

class TitleViewCoordinator: ScreenCoordinator {
    let navigationComponent = ScreenCoordinatorComponent()

    init() {
        navigationComponent.setView(TitleView(title: "Splash Screen"))
    }
}

let screenCoordinator: ScreenCoordinator = TitleViewCoordinator()

struct ActionsView: View {

    struct Action {
        let title: String
        let action: () -> Void
    }

    class ViewModel: ObservableObject {
        
        @Published var title: String
        @Published var actions: [Action]

        init(title: String, actions: [Action]) {
            self.title = title
            self.actions = actions
        }
    }

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack {
            Text(viewModel.title).font(.title)
            ForEach(viewModel.actions, id: \.title) { action in
                Button(action: {
                    action.action()
                }, label: {
                    Text(action.title).font(.callout)
                })
            }
        }.navigationTitle(viewModel.title)
    }
}

class ActionsViewScreenCoordinator: ScreenCoordinator {
    let navigationComponent: ScreenCoordinatorComponent
    let viewModel: ActionsView.ViewModel

    init() {
        viewModel = ActionsView.ViewModel(title: "Actions View", actions: [])
        navigationComponent = ScreenCoordinatorComponent(view: ActionsView(viewModel: viewModel))
    }
}

struct HowToUse {
    func createSequenceCoordinator() async -> SequenceCoordinator {
        let sequenceCoordinator = await DefaultSequenceCoordinator(screenCoordinators: [
            TitleView(title: "First screen").toScreenCoordinator(),
            TitleView(title: "Second screen").toScreenCoordinator(),
            TitleView(title: "Third screen").toScreenCoordinator(),
        ])
        return sequenceCoordinator
    }
}

//func createActionsViewsScreenCoordinator() -> ScreenCoordinator {
//    let screenCoordinator: ScreenCoordinator = DefaultScreenCoordinator(view: ActionsView(title: "Plain View", actions: []))
//    let screenCoordinator: ScreenCoordinator = ActionsView(title: "Plain View", actions: []).toScreenCoordinator()
//}
