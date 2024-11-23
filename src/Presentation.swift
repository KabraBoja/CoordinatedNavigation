import Foundation
import SwiftUI

// Known Apple Memory leak bug: https://developer.apple.com/forums/thread/737967?answerId=767599022#767599022
public class PresentingScreenCoordinatorComponent: ObservableObject {

    public static var presentationWaitingTime: Double = 0.5

    struct Parent {
        weak var stack: StackCoordinatorComponent?
        weak var screen: ScreenCoordinatorComponent?

        init(stack: StackCoordinatorComponent?) {
            self.stack = stack
            self.screen = nil
        }

        init(screen: ScreenCoordinatorComponent?) {
            self.stack = nil
            self.screen = screen
        }
    }

    enum PresentedCoordinator {
        case screen(ScreenCoordinator)
        case stack(StackCoordinator)

        func getView() -> AnyView {
            switch self {
            case .screen(let screen):
                screen.getView()
            case .stack(let stack):
                stack.getView()
            }
        }

        func getCoordinator() -> ViewCoordinator {
            switch self {
            case .screen(let screen):
                screen
            case .stack(let stack):
                stack
            }
        }

        func destroyComponent() async {
            switch self {
            case .screen(let screen):
                await screen.navigationComponent.destroyComponent()
            case .stack(let stack):
                await stack.navigationComponent.destroyComponent()
            }
        }
    }

    public enum PresentationMode {
        case sheet
        case fullscreen
    }

    public var onUpdate: (Bool) -> Void = { _ in }
    @Published var presentedCoordinator: PresentedCoordinator?
    @Published private var isPresenting: Bool = false
    @Published var presentationMode: PresentationMode = .sheet
    var parentDidAppear: Bool = false
    var parent: Parent?
    private var initialIsPresenting: Bool = false

    func setParent(screen: ScreenCoordinatorComponent) {
        parent = Parent(screen: screen)
    }

    func setParent(stack: StackCoordinatorComponent) {
        parent = Parent(stack: stack)
    }

    @MainActor
    public func present(screen: ScreenCoordinator, mode: PresentationMode) async {
        presentationMode = mode
        if parentDidAppear {
            isPresenting = true
            onUpdate(isPresenting)
        } else {
            initialIsPresenting = true
        }
        presentedCoordinator = .screen(screen)
    }

    @MainActor
    public func present(stack: StackCoordinator, mode: PresentationMode) async {
        presentationMode = mode
        if parentDidAppear {
            isPresenting = true
            onUpdate(isPresenting)
        } else {
            initialIsPresenting = true
        }
        presentedCoordinator = .stack(stack)
    }

    @MainActor
    public func dismiss() async {
        if parentDidAppear {
            isPresenting = false
            onUpdate(isPresenting)
        } else {
            initialIsPresenting = false
        }
        presentedCoordinator = nil
    }

    struct PresentingView<Content: View>: View {
        @ObservedObject var coordinator: PresentingScreenCoordinatorComponent
        var content: Content

        var body: some View {
            createView()
        }

        @ViewBuilder
        func createView() -> some View {
            switch coordinator.presentationMode {
            case .sheet:
                content.onAppear {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(PresentingScreenCoordinatorComponent.presentationWaitingTime)) // Ideally we should detect when the presentation animation has finished.
                        if !coordinator.parentDidAppear {
                            coordinator.parentDidAppear = true
                            coordinator.isPresenting = coordinator.initialIsPresenting
                            coordinator.onUpdate(coordinator.isPresenting)
                        }
                    }
                }.sheet(isPresented: $coordinator.isPresenting, onDismiss: { [weak coordinator] in
                    let presentedCoordinator = coordinator?.presentedCoordinator
                    Task {
                        await presentedCoordinator?.destroyComponent()
                    }
                    coordinator?.presentedCoordinator = nil
                }, content: { [weak coordinator] in
                    return coordinator?.presentedCoordinator?.getView()
                })
            case .fullscreen:
                content.onAppear {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(PresentingScreenCoordinatorComponent.presentationWaitingTime)) // Ideally we should detect when the presentation animation has finished.
                        if !coordinator.parentDidAppear {
                            coordinator.parentDidAppear = true
                            coordinator.isPresenting = coordinator.initialIsPresenting
                            coordinator.onUpdate(coordinator.isPresenting)
                        }
                    }
                }.fullScreenCover(isPresented: $coordinator.isPresenting, onDismiss: { [weak coordinator] in
                    //presentingComponent?.parent?.presentingComponent = nil
                    let presentedCoordinator = coordinator?.presentedCoordinator
                    Task {
                        await presentedCoordinator?.destroyComponent()
                    }
                    coordinator?.presentedCoordinator = nil
                }, content: { [weak coordinator] in
                    coordinator?.presentedCoordinator?.getView()
                })
            }
        }
    }
}

