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
            case chainedPresentations
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
                CustomScreenCoordinator.Action(id: "Deeplink: Chained presentations", closure: { [weak self] in
                    guard let self else { return }
                    self.deeplinkPressed(deepLink: .chainedPresentations)
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
                case .chainedPresentations:
                    let presentingScreen0 = SimpleTitleScreenCoordinator(title: "Presenting Screen 0")
                    await navigationComponent.push(screen: presentingScreen0)

                    let presentingScreen1 = SimpleTitleScreenCoordinator(title: "Presenting Screen 1")
                    let presentedSequence1 = await DefaultSequenceCoordinator(screenCoordinator: presentingScreen1)
                    let presentedStack1 = await DefaultStackCoordinator(sequenceCoordinator: presentedSequence1)
                    await presentingScreen0.navigationComponent.getPresentingComponent().present(stack: presentedStack1, mode: .sheet)

                    let presentingScreen2 = SimpleTitleScreenCoordinator(title: "Presenting Screen 2")
                    let presentedSequence2 = await DefaultSequenceCoordinator(screenCoordinator: presentingScreen2)
                    let presentedStack2 = await DefaultStackCoordinator(sequenceCoordinator: presentedSequence2)
                    await presentingScreen1.navigationComponent.getPresentingComponent().present(stack: presentedStack2, mode: .sheet)

                    let presentingScreen3 = SimpleTitleScreenCoordinator(title: "Presenting Screen 3")
                    let presentedSequence3 = await DefaultSequenceCoordinator(screenCoordinator: presentingScreen3)
                    let presentedStack3 = await DefaultStackCoordinator(sequenceCoordinator: presentedSequence3)
                    await presentingScreen2.navigationComponent.getPresentingComponent().present(stack: presentedStack3, mode: .sheet)
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
