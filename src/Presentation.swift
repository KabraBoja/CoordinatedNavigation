import Foundation
import SwiftUI

// Known Apple Memory leak bug: https://developer.apple.com/forums/thread/737967?answerId=767599022#767599022
public class PresentingScreenCoordinatorComponent: ObservableObject {

    public static let presentationWaitingTime: Double = 0.5

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

    enum PresentedEntity {
        case screen(ScreenCoordinatorEntity)
        case stack(StackCoordinatorEntity)

        func getView() -> AnyView {
            switch self {
            case .screen(let screen):
                screen.getView()
            case .stack(let stack):
                stack.getView()
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

    @Published var presentedEntity: PresentedEntity?
    @Published private var isPresenting: Bool = false
    private var initialIsPresenting: Bool = false
    @Published var presentationMode: PresentationMode = .sheet
    var parentDidAppear: Bool = false

    var parent: Parent?

    func setParent(screen: ScreenCoordinatorComponent) {
        parent = Parent(screen: screen)
    }

    func setParent(stack: StackCoordinatorComponent) {
        parent = Parent(stack: stack)
    }

    @MainActor
    public func present(screen: ScreenCoordinatorEntity, mode: PresentationMode) async {
        presentationMode = mode
        if parentDidAppear {
            isPresenting = true
        } else {
            initialIsPresenting = true
        }
        presentedEntity = .screen(screen)
    }

    @MainActor
    public func present(stack: StackCoordinatorEntity, mode: PresentationMode) async {
        presentationMode = mode
        if parentDidAppear {
            isPresenting = true
        } else {
            initialIsPresenting = true
        }
        presentedEntity = .stack(stack)
    }

    @MainActor
    public func dismiss() async {
        if parentDidAppear {
            isPresenting = false
        } else {
            initialIsPresenting = false
        }
        presentedEntity = nil
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
                        }
                    }
                }.sheet(isPresented: $coordinator.isPresenting, onDismiss: { [weak coordinator] in
                    //presentingComponent?.parent?.presentingComponent = nil
                    let presentedEntity = coordinator?.presentedEntity
                    Task {
                        await presentedEntity?.destroyComponent()
                    }
                    coordinator?.presentedEntity = nil
                }, content: { [weak coordinator] in
                    coordinator?.presentedEntity?.getView()
                })
            case .fullscreen:
                content.onAppear {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(PresentingScreenCoordinatorComponent.presentationWaitingTime)) // Ideally we should detect when the presentation animation has finished.
                        if !coordinator.parentDidAppear {
                            coordinator.parentDidAppear = true
                            coordinator.isPresenting = coordinator.initialIsPresenting
                        }
                    }
                }.fullScreenCover(isPresented: $coordinator.isPresenting, onDismiss: { [weak coordinator] in
                    //presentingComponent?.parent?.presentingComponent = nil
                    let presentedEntity = coordinator?.presentedEntity
                    Task {
                        await presentedEntity?.destroyComponent()
                    }
                    coordinator?.presentedEntity = nil
                }, content: { [weak coordinator] in
                    coordinator?.presentedEntity?.getView()
                })
            }
        }
    }
}

