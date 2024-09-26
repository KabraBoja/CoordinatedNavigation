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


    func createAuthenticationSequenceCoordinator() async -> SequenceCoordinator {
        let sequenceCoordinator = DefaultSequenceCoordinator()

        let loginScreen = await LoginView(output: { action in
            switch action {
            case .registerButtonPressed:
                let registerScreen = await TitleView(title: "Register screen").toScreenCoordinator()
                await sequenceCoordinator.navigationComponent.push(screen: registerScreen)
            case .forgotPasswordButtonPressed:
                let forgotPasswordScreen = await TitleView(title: "Forgot password screen").toScreenCoordinator()
                await sequenceCoordinator.navigationComponent.push(screen: forgotPasswordScreen)
            }
        }).toScreenCoordinator()

        await sequenceCoordinator.navigationComponent.set(screen: loginScreen)

        return sequenceCoordinator
    }

    //let authenticationSequenceCoordinator = await createAuthenticationSequenceCoordinator()

    func createRootStackCoordinator() async -> StackCoordinator {
        let authenticationSequenceCoordinator = await createAuthenticationSequenceCoordinator()
        return await DefaultStackCoordinator(sequenceCoordinator: authenticationSequenceCoordinator)
    }
}

class AuthenticationSequenceCoordinator: SequenceCoordinator {
    let navigationComponent = SequenceCoordinatorComponent()

    init() async {
        await navigationComponent.set(screen: createLoginScreen())
    }

    func createRegisterScreen() async -> ScreenCoordinator {
        await TitleView(title: "Register screen").toScreenCoordinator()
    }

    func createForgotPasswordScreen() async -> ScreenCoordinator {
        await TitleView(title: "Forgot password screen").toScreenCoordinator()
    }

    func createLoginScreen() async -> ScreenCoordinator {
        await LoginView(output: { action in
            switch action {
            case .registerButtonPressed:
                await self.navigationComponent.push(screen: self.createRegisterScreen())
            case .forgotPasswordButtonPressed:
                await self.navigationComponent.push(screen: self.createForgotPasswordScreen())
            }
        }).toScreenCoordinator()
    }
}

struct LoginView: View {

    // Navigation is never done in the view, it's always delegated to the parent sequence (in this case using a closure).
    enum Output {
        case registerButtonPressed
        case forgotPasswordButtonPressed
    }

    let output: (Output) async -> Void

    // Assume we are using a view model or whatever you need to keep your state and your behaviour
    @State private var username: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack(spacing: 16.0) {
            TextField("Username", text: $username)
            SecureField("Password", text: $password)

            Button("Login") {
                // Assume an internal logic is called (no navigation needed)
            }

            Button("Register") {
                Task { await output(.registerButtonPressed) }
            }

            Button("Forgot password?") {
                Task { await output(.forgotPasswordButtonPressed) }
            }

            Spacer()
        }
        .navigationTitle("Login screen")
    }
}

//func createActionsViewsScreenCoordinator() -> ScreenCoordinator {
//    let screenCoordinator: ScreenCoordinator = DefaultScreenCoordinator(view: ActionsView(title: "Plain View", actions: []))
//    let screenCoordinator: ScreenCoordinator = ActionsView(title: "Plain View", actions: []).toScreenCoordinator()
//}
