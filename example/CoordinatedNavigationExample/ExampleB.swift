import Foundation
import SwiftUI
import CoordinatedNavigation

struct ExampleB { // Namespace

    class RootSequenceCoordinator: SequenceCoordinatorEntity {
        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

        enum DeeplinkExample {
            case simplePost
            case deepPost
            case presentLogin
        }

        init() async {
            let splashScreenCoordinator = CustomScreenCoordinator(title: "Splash Screen", actions: [], isBackAllowed: false)
            splashScreenCoordinator.actions = [
                CustomScreenCoordinator.Action(id: "Deeplink: Simple Post", closure: { [weak self] in
                    guard let self else { return }
                    self.deeplinkPressed(deepLink: .simplePost)
                }),
                CustomScreenCoordinator.Action(id: "Deeplink: Deep Recommended Post", closure: { [weak self] in
                    guard let self else { return }
                    self.deeplinkPressed(deepLink: .deepPost)
                }),
                CustomScreenCoordinator.Action(id: "Deeplink: Present Login", closure: { [weak self] in
                    guard let self else { return }
                    self.deeplinkPressed(deepLink: .presentLogin)
                }),
            ]
            await navigationComponent.set(screen: splashScreenCoordinator)
        }

        func deeplinkPressed(deepLink: DeeplinkExample) {
            Task {
                switch deepLink {
                case .simplePost:
                    await navigationComponent.push(screen: SimpleTitleScreenCoordinator(title: "Simple Post"))
                case .deepPost:
                    await navigationComponent.push(sequence: OnboardingSequenceCoordinator())
                    await navigationComponent.push(sequence: AuthenticationSequenceCoordinator())
                    await navigationComponent.push(sequence: FeedSequenceCoordinator())
                    await navigationComponent.push(screen: SimpleTitleScreenCoordinator(title: "Recommended Post"))
                case .presentLogin:
                    let simpleScreen = SimpleTitleScreenCoordinator(title: "Step 3 Presents")
                    await navigationComponent.push(screens: [
                        SimpleTitleScreenCoordinator(title: "Step 1"),
                        SimpleTitleScreenCoordinator(title: "Step 2"),
                        simpleScreen
                    ])

                    let authenticateStack = await AuthenticationStackCoordinator()
                    await simpleScreen.navigationComponent.getPresentingComponent().present(stack: authenticateStack, mode: .sheet)
                }
            }
        }
    }

    class OnboardingSequenceCoordinator: SequenceCoordinatorEntity {
        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

        init() async {
            await navigationComponent.set(screens: [
                SimpleTitleScreenCoordinator(title: "Onboarding 1"),
                SimpleTitleScreenCoordinator(title: "Onboarding 2"),
                SimpleTitleScreenCoordinator(title: "Onboarding 3")
            ])
        }
    }

    class AuthenticationStackCoordinator: StackCoordinatorEntity {
        var navigationComponent: StackCoordinatorComponent = StackCoordinatorComponent()

        init() async {
            await navigationComponent.set(sequence: AuthenticationSequenceCoordinator())
        }
    }

    class AuthenticationSequenceCoordinator: SequenceCoordinatorEntity {
        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

        init() async {
            await navigationComponent.set(screens: [
                SimpleTitleScreenCoordinator(title: "BenefitsOfLogin"),
                SimpleTitleScreenCoordinator(title: "Login"),
            ])
        }
    }

    class FeedSequenceCoordinator: SequenceCoordinatorEntity {
        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

        init() async {
            await navigationComponent.set(screens: [
                SimpleTitleScreenCoordinator(title: "Feed"),
                SimpleTitleScreenCoordinator(title: "Post"),
                SimpleTitleScreenCoordinator(title: "Recommended")
            ])
        }
    }
}
