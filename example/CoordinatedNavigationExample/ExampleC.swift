import Foundation
import CoordinatedNavigation
import SwiftUI

struct ExampleC {

    class CustomTabBarCoordinator: ScreenCoordinatorEntity, ObservableObject {
        let navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()

        @Published var selectedTab: Int = 0
        @Published var firstTabCoordinator: ViewEntity
        @Published var secondTabCoordinator: ViewEntity

        init() async {
            firstTabCoordinator = await FirstTabStackCoordinator()
            secondTabCoordinator = SecondTabStackCoordinator()
            navigationComponent.setView(ContentView(coordinator: self))
        }

        struct ContentView: View {

            @ObservedObject var coordinator: CustomTabBarCoordinator

            var body: some View {
                //                coordinator.firstTabCoordinator.getView()
                TabView(selection: $coordinator.selectedTab,
                        content:  {
                    coordinator.firstTabCoordinator.getView().tabItem { Text("Tab 1") }.tag(0)
                    coordinator.secondTabCoordinator.getView().tabItem { Text("Tab 2")  }.tag(1)
                })
            }
        }

        deinit {
            print("DESTROYED")
        }
    }

    class FirstTabStackCoordinator: StackCoordinatorEntity {
        let navigationComponent: StackCoordinatorComponent = StackCoordinatorComponent(rootView: Text("Tab Label 1"))

        init() async {
            await navigationComponent.set(sequence: FirstTabSequenceCoordinator())
        }
    }

    class SecondTabStackCoordinator: StackCoordinatorEntity {
        let navigationComponent: StackCoordinatorComponent = StackCoordinatorComponent(rootView: Text("Tab Label 2"))
    }

    class FirstTabSequenceCoordinator: SequenceCoordinatorEntity {
        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

        init() async {
            await navigationComponent.set(screens: [
                SimpleTitleScreenCoordinator(title: "First"),
                SimpleTitleScreenCoordinator(title: "Second"),
                SimpleTitleScreenCoordinator(title: "Third")
            ])
        }

        deinit {
            print("FirstTabSequenceCoordinator: DEINIT")
        }
    }


    class TestiOSBugStackInTabViewCoordinator: ObservableObject {

        @Published var navigationPath: NavigationPath
        @Published var selectedTab: Int = 0

        let viewsDict: [UUID: AnyView]

        let id0: UUID = UUID()
        let id1: UUID = UUID()
        let id2: UUID = UUID()

        init() {
            viewsDict = [
                id0: Text("Push 0").toAnyView(),
                id1: Text("Push 1").toAnyView(),
                id2: Text("Push 2").toAnyView()
            ]
            navigationPath = NavigationPath([id0, id1, id2])
        }

        func getTabView() -> AnyView { InTabView(coordinator: self).toAnyView() }

        func getStackView() -> AnyView { InStackView(coordinator: self).toAnyView() }

        struct InTabView: View {

            @ObservedObject var coordinator: TestiOSBugStackInTabViewCoordinator

            var body: some View {
                TabView(selection: $coordinator.selectedTab,
                        content:  {
                    NavigationStack(path: $coordinator.navigationPath, root: {
                        Text("Root View").navigationDestination(for: UUID.self) { item in
                            coordinator.viewsDict[item]
                        }
                    })
                    .tabItem { Text("Tab 1") }
                    .tag(0)

                    Text("Second Tab").tabItem { Text("Tab 2")  }.tag(1)
                })
            }
        }

        struct InStackView: View {

            @ObservedObject var coordinator: TestiOSBugStackInTabViewCoordinator

            var body: some View {
                NavigationStack(path: $coordinator.navigationPath, root: {
                    Text("Root View").navigationDestination(for: UUID.self) { item in
                        coordinator.viewsDict[item]
                    }
                })
                .tag(0)
            }
        }
    }
}
