import Foundation
import SwiftUI
import CoordinatedNavigation

struct ExampleA { // Namespace

    class RootStackCoordinator: StackCoordinatorEntity {
        let navigationComponent: StackCoordinatorComponent = StackCoordinatorComponent()

        init() async {
            await navigationComponent.set(sequence: RootSequenceCoordinator())
        }
    }

    class RootSequenceCoordinator: SequenceCoordinatorEntity {
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

    class OnboardingSequenceCoordinator: SequenceCoordinatorEntity {

        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()
        let onOnboardingFinished: () async -> Void

        init(onOnboardingFinished: @escaping () async -> Void) async {
            self.onOnboardingFinished = onOnboardingFinished
            await navigationComponent.set(screen: createOnboardingStep1())
        }

        private func createOnboardingStep1() -> ScreenCoordinatorEntity {

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
                    guard let screenCoordinator else { return }
                    await screenCoordinator.navigationComponent.getPresentingComponent().present(
                        stack: RootStackCoordinator(),
                        mode: .sheet
                        //                    screen: CustomScreenCoordinator(title: "Presented Screen", actions: [], isBackAllowed: true)
                    )
                })
            ]
            return screenCoordinator
        }

        private func createOnboardingStep2() -> ScreenCoordinatorEntity {
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

        private func createOnboardingStep3() -> ScreenCoordinatorEntity {
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

    class SearchSequenceCoordinator: SequenceCoordinatorEntity {
        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

        init() async {
            await navigationComponent.set(screen: createSearchList())
        }

        private func createSearchList() -> ScreenCoordinatorEntity {
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

        private func createSearchDetail(title: String) -> ScreenCoordinatorEntity {
            let detail = CustomScreenCoordinator(
                title: title,
                actions: [],
                isBackAllowed: true
            )
            detail.actions = [
                CustomScreenCoordinator.Action(id: "Detail Map", closure: { [weak detail] in
                    guard let detail else { return }
                    await detail.navigationComponent.getPresentingComponent().present(
                        screen: SimpleTitleScreenCoordinator(title: "Detail Map"),
                        mode: .sheet
                    )
                })
            ]
            return detail
        }
    }
}
