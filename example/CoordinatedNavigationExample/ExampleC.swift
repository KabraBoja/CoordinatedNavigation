import Foundation
import CoordinatedNavigation
import SwiftUI

struct ExampleC { // Namespace

    class CustomTabBarCoordinator: ScreenCoordinator, ObservableObject {
        let navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()

        @Published var selectedTab: Int = 0
        @Published var firstTabCoordinator: ViewCoordinator
        @Published var secondTabCoordinator: ViewCoordinator
        @Published var wasInitialized: Bool = false

        init() async {
            firstTabCoordinator = await DefaultStackCoordinator(sequenceCoordinator: FirstTabSequenceCoordinator())
            secondTabCoordinator = await DefaultStackCoordinator(sequenceCoordinator: DefaultSequenceCoordinator(screenCoordinator: SimpleTitleScreenCoordinator(title: "Second Tab")))
            navigationComponent.setView(ContentView(coordinator: self))
        }

        struct ContentView: View {

            @ObservedObject var coordinator: CustomTabBarCoordinator

            var body: some View {
                TabView(selection: $coordinator.selectedTab, content:  {
                    if coordinator.wasInitialized {
                        coordinator.firstTabCoordinator.getView().tabItem { Text("Tab 1") }.tag(0)
                        coordinator.secondTabCoordinator.getView().tabItem { Text("Tab 2")  }.tag(1)
                    }
                }).task {
                    if !coordinator.wasInitialized {
                        coordinator.wasInitialized = true
                    }
                }
            }
        }

        deinit {
            print("CustomTabBarCoordinator: DEINIT")
        }
    }

    class FirstTabSequenceCoordinator: SequenceCoordinator {
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

    struct TestiOSBugStackInTabView: View {

        @State var navigationPath: NavigationPath = NavigationPath()
        @State var selectedTab: Int = 0

        let viewsDict: [UUID: Text]

        static let id0: UUID = UUID()
        static let id1: UUID = UUID()
        static let id2: UUID = UUID()

        init() {
            viewsDict = [
                Self.id0: Text("Push 0"),
                Self.id1: Text("Push 1"),
                Self.id2: Text("Push 2")
            ]
        }

        var body: some View {
            TabView(selection: $selectedTab,
                    content:  {
                NavigationStack(path: $navigationPath, root: {
                    Text("Root View").navigationDestination(for: UUID.self) { item in
                        viewsDict[item]
                        // Text("TEST")
                    }
                })
                .task {
                    print("Tab 1 appears")
                    navigationPath.append(Self.id0)
                    navigationPath.append(Self.id1)
                    navigationPath.append(Self.id2)
                }
                .tabItem { Text("Tab 1") }
                .tag(0)

                Text("Second Tab")
                    .task {
                        print("Tab 2 appears")
                    }
                    .tabItem { Text("Tab 2") }
                    .tag(1)
            })
        }
    }
}
