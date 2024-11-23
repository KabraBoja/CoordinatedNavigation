import Foundation
import SwiftUI
import CoordinatedNavigation

struct ExampleA { // Namespace

    class RootSequenceCoordinator: SequenceCoordinator {
        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()
        let isFirstAppLaunch: Bool = true

        init() async {
            if isFirstAppLaunch {
                await navigationComponent.set(sequence: OnboardingSequenceCoordinator(onOnboardingFinished: { [weak navigationComponent] in
                    guard let navigationComponent else { return }
                    await navigationComponent.set(sequence: SearchSequenceCoordinator())
                }))
            } else {
                await navigationComponent.set(sequence: SearchSequenceCoordinator())
            }
        }
    }

    class OnboardingSequenceCoordinator: SequenceCoordinator {

        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()
        let onOnboardingFinished: () async -> Void

        init(onOnboardingFinished: @escaping () async -> Void) async {
            self.onOnboardingFinished = onOnboardingFinished
            await navigationComponent.set(screen: createOnboardingStep1())
        }

        private func createOnboardingStep1() -> ScreenCoordinator {

            let screenCoordinator = CustomScreenCoordinator(
                title: "Step 1",
                actions: [],
                isBackAllowed: false
            )
            screenCoordinator.actions = [
                CustomScreenCoordinator.Action(id: "Next step", closure: { [weak navigationComponent] in
                    guard let navigationComponent else { return }
                    await navigationComponent.push(screen: self.createOnboardingStep2())
                }),
                CustomScreenCoordinator.Action(id: "Login", closure: { [weak screenCoordinator] in
                    print("login action")
                    guard let screenCoordinator else { return }

                    let loginSequenceCoordinator = await DefaultSequenceCoordinator(screenCoordinator: DefaultScreenCoordinator(view: Text("Login")))
                    await screenCoordinator.navigationComponent.presentingComponent.present(
                        stack: DefaultStackCoordinator(sequenceCoordinator: loginSequenceCoordinator),
                        mode: .sheet
                    )
                })
            ]
            return screenCoordinator
        }

        private func createOnboardingStep2() -> ScreenCoordinator {
            CustomScreenCoordinator(
                title: "Step 2",
                actions: [
                    CustomScreenCoordinator.Action(id: "Go to next step", closure: { [weak self] in
                        guard let self else { return }
                        await self.navigationComponent.push(screen: self.createOnboardingStep3())
                    }),
                ],
                isBackAllowed: true
            )
        }

        private func createOnboardingStep3() -> ScreenCoordinator {
            CustomScreenCoordinator(
                title: "Step 3",
                actions: [
                    CustomScreenCoordinator.Action(id: "End Onboarding", closure: { [weak self] in
                        guard let self else { return }
                        await self.onOnboardingFinished()
                    }),
                    CustomScreenCoordinator.Action(id: "Repeat Onboarding", closure: { [weak self] in
                        guard let self else { return }
                        await self.navigationComponent.popToFirst()
                    })
                ],
                isBackAllowed: true
            )
        }
    }

    class SearchSequenceCoordinator: SequenceCoordinator {
        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

        init() async {
            await navigationComponent.set(screen: createSearchList())
        }

        private func createSearchList() -> ScreenCoordinator {
            CustomScreenCoordinator(
                title: "Search List",
                actions: [
                    CustomScreenCoordinator.Action(id: "Deatil A", closure: { [weak self] in
                        guard let self else { return }
                        await self.navigationComponent.push(screen: createSearchDetail(title: "Detail A"))
                    }),
                    CustomScreenCoordinator.Action(id: "Deatil B", closure: { [weak self] in
                        guard let self else { return }
                        await self.navigationComponent.push(screen: createSearchDetail(title: "Detail B"))
                    }),
                    CustomScreenCoordinator.Action(id: "Deatil C", closure: { [weak self] in
                        guard let self else { return }
                        await self.navigationComponent.push(screen: createSearchDetail(title: "Detail C"))
                    })
                ],
                isBackAllowed: false
            )
        }

        private func createSearchDetail(title: String) -> ScreenCoordinator {
            let detail = CustomScreenCoordinator(
                title: title,
                actions: [],
                isBackAllowed: true
            )
            detail.actions = [
                CustomScreenCoordinator.Action(id: "Detail Map", closure: { [weak detail] in
                    guard let detail else { return }
                    await detail.navigationComponent.presentingComponent.present(
                        screen: SimpleTitleScreenCoordinator(title: "Detail Map"),
                        mode: .sheet
                    )
                })
            ]
            return detail
        }
    }
}
