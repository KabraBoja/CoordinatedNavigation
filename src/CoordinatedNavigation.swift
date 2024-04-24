import Foundation
import SwiftUI

public typealias CoordinatorID = UUID

public protocol Component {
    var navigationId: CoordinatorID { get }
}

public protocol ViewComponent: Component {
    func getView() -> AnyView
}

public protocol ViewEntity {
    func getView() -> AnyView
}

public protocol StackCoordinatorEntity: AnyObject, ViewEntity {
    var navigationComponent: StackCoordinatorComponent { get }
}

public protocol SequenceCoordinatorEntity: AnyObject {
    var navigationComponent: SequenceCoordinatorComponent { get }
}

public protocol ScreenCoordinatorEntity: AnyObject, ViewEntity {
    var navigationComponent: ScreenCoordinatorComponent { get }
}

public protocol SequenceableEntity {}

public extension StackCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }

    func getView() -> AnyView {
        navigationComponent.getView()
    }
}

public extension SequenceCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }
}

public extension ScreenCoordinatorEntity {
    var navigationId: CoordinatorID {
        navigationComponent.navigationId
    }

    func getView() -> AnyView {
        navigationComponent.getView()
    }
}

public class ScreenCoordinatorComponent: ObservableObject, ViewComponent {

    public let navigationId: CoordinatorID = CoordinatorID()

    @Published var view: AnyView?
    @Published var presentingComponent: PresentingScreenCoordinatorComponent?
    @Published private var wasInitialized: Bool = false

    public init() {}

    public init(view: some View) {
        self.view = view.toAnyView()
    }

    public func getView() -> AnyView {
        ContentView(coordinator: self).toAnyView()
    }

    public func setView(_ view: some View) {
        self.view = view.toAnyView()
    }

    @MainActor
    public func getPresentingComponent() async -> PresentingScreenCoordinatorComponent {
        if let presentingComponent = presentingComponent {
            return presentingComponent
        } else {
            let presentingComponent = PresentingScreenCoordinatorComponent()
            presentingComponent.setParent(screen: self)
            self.presentingComponent = presentingComponent
            return presentingComponent
        }
    }

    struct ContentView: View {
        @ObservedObject var coordinator: ScreenCoordinatorComponent

        var body: some View {
            if coordinator.wasInitialized, let presentingComponent = coordinator.presentingComponent {
                PresentingScreenCoordinatorComponent.PresentingView(presentingComponent: presentingComponent, content: getView())
            } else {
                getView().task {
                    coordinator.wasInitialized = true
                }
            }
        }

        func getView() -> AnyView {
            if let view = coordinator.view {
                view
            } else {
                EmptyView().toAnyView()
            }
        }
    }

    @MainActor
    func destroyComponent() async {
        //print("Screen destroyed")
        presentingComponent = nil
        view = nil
    }
}

// Known Apple Memory leak bug: https://developer.apple.com/forums/thread/737967?answerId=767599022#767599022
public class PresentingScreenCoordinatorComponent: ObservableObject {

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
    @Published var isPresenting: Bool = false
    @Published var presentationMode: PresentationMode = .sheet

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
        isPresenting = true
        presentedEntity = .screen(screen)
    }

    @MainActor
    public func present(stack: StackCoordinatorEntity, mode: PresentationMode) async {
        presentationMode = mode
        isPresenting = true
        presentedEntity = .stack(stack)
    }

    @MainActor
    public func dismiss() async {
        isPresenting = false
        presentedEntity = nil
    }

    struct PresentingView<Content: View>: View {
        @ObservedObject var presentingComponent: PresentingScreenCoordinatorComponent
        var content: Content

        var body: some View {
            switch presentingComponent.presentationMode {
            case .sheet:
                content.sheet(isPresented: $presentingComponent.isPresenting, onDismiss: { [weak presentingComponent] in
                    //presentingComponent?.parent?.presentingComponent = nil
                    let presentedEntity = presentingComponent?.presentedEntity
                    Task {
                        await presentedEntity?.destroyComponent()
                    }
                    presentingComponent?.presentedEntity = nil
                }, content: { [weak presentingComponent] in
                    presentingComponent?.presentedEntity?.getView()
                })
            case .fullscreen:
                content.fullScreenCover(isPresented: $presentingComponent.isPresenting, onDismiss: { [weak presentingComponent] in
                    //presentingComponent?.parent?.presentingComponent = nil
                    let presentedEntity = presentingComponent?.presentedEntity
                    Task {
                        await presentedEntity?.destroyComponent()
                    }
                    presentingComponent?.presentedEntity = nil
                }, content: { [weak presentingComponent] in
                    presentingComponent?.presentedEntity?.getView()
                })
            }
        }
    }
}

enum Event {
    case removeCoordinatorsNeeded([CoordinatorID])
    case navigationPathUpdateNeeded
}

enum PathRepresentation {
    case path(String)
    case array([CoordinatorID])
}

public class StackCoordinatorComponent: ObservableObject, ViewComponent {

    public let navigationId: CoordinatorID = CoordinatorID()

    @Published var navigationPath: NavigationPath = NavigationPath()
    @Published var sequenceCoordinator: SequenceCoordinatorEntity?
    let presentingComponent: PresentingScreenCoordinatorComponent = PresentingScreenCoordinatorComponent()

    var wasInitialized: Bool = false

    public init() {
        self.presentingComponent.setParent(stack: self)
    }

    public init(sequence: SequenceCoordinatorEntity) {
        self.sequenceCoordinator = sequence
        self.presentingComponent.setParent(stack: self)
    }

    public func getView() -> AnyView {
        StackCoordinatorComponentView(coordinator: self).toAnyView()
    }

    struct StackCoordinatorComponentView: View {

        @ObservedObject var coordinator: StackCoordinatorComponent

        init(coordinator: StackCoordinatorComponent) {
            self.coordinator = coordinator
        }

        var body: some View {
            PresentingScreenCoordinatorComponent.PresentingView(
                presentingComponent: coordinator.presentingComponent,
                content: NavigationStack(path: $coordinator.navigationPath) {
                    if coordinator.sequenceCoordinator != nil, let firstView = coordinator.getFirstCoordinatorView() {
                        firstView.navigationDestination(for: UUID.self) { item in
                            coordinator.getCoordinatorView(item).onDisappear {
                                Task { @MainActor in
                                    let path = coordinator.navigationPath.getPathRepresentation()
                                    await coordinator.removeUnusedCoordinators(path: path)
                                }

                            }
                        }
                    }
                }.task {
                    if !coordinator.wasInitialized {
                        coordinator.wasInitialized = true
                        coordinator.updatePath()
                    }
                }
            )
        }
    }

    @MainActor
    public func set(sequence: SequenceCoordinatorEntity) async {
        await pop()
        sequence.navigationComponent.parent = SequenceCoordinatorComponent.Parent(stack: self)
        sequenceCoordinator = sequence
        updatePath()
    }

    @MainActor
    public func pop() async {
        await sequenceCoordinator?.navigationComponent.destroyComponent()
        sequenceCoordinator = nil
        updatePath()
    }

    func updatePath() {
        Task { @MainActor in
            if self.wasInitialized {
                try? await Task.sleep(for: .milliseconds(1))
                let arrayOfId: [CoordinatorID] = NavigationTree.getIDTreeRecursive(from: NavigationTree.Node(self))
                let withoutFirst = arrayOfId.dropFirst()
                self.navigationPath = NavigationPath(withoutFirst)
            }
        }
    }

    @MainActor
    func eventReceived(event: Event) async {
        switch event {
        case .navigationPathUpdateNeeded:
            updatePath()
        case .removeCoordinatorsNeeded(let coordinatorsIDs):
            await removeCoordinators(iDs: coordinatorsIDs)
        }
    }

    @MainActor
    private func removeCoordinators(iDs: [CoordinatorID]) async {
        guard let sequenceCoordinator = sequenceCoordinator else { return }
        if await sequenceCoordinator.navigationComponent.removeCoordinators(iDs: iDs) {
            await pop()
        }
    }

    @MainActor
    private func removeUnusedCoordinators(path: String) async {
        guard let sequenceCoordinator = sequenceCoordinator else { return }

        var pathAddingFirst: String = path
        if let firstId = NavigationTree.getFirstComponent(from: NavigationTree.Node(self))?.navigationId {
            pathAddingFirst.append(firstId.uuidString)
        }

        let childInPath = await sequenceCoordinator.navigationComponent.removeUnusedCoordinators(path: pathAddingFirst)
        if !childInPath {
            self.sequenceCoordinator = nil
        }
    }

    private func getCoordinatorView(_ id: UUID) -> AnyView? {
        if let coordinator = NavigationTree.getComponent(from: NavigationTree.Node(self), navigationId: id),
           let screenCoordinator = coordinator as? ScreenCoordinatorComponent {
            return screenCoordinator.getView()
        }
        return nil
    }

    private func getFirstCoordinatorView() -> AnyView? {
        if let coordinator = NavigationTree.getFirstComponent(from: NavigationTree.Node(self)),
           let screenCoordinator = coordinator as? ScreenCoordinatorComponent {
            return screenCoordinator.getView()
        }
        return nil
    }

    @MainActor
    public func getPresentingComponent() async -> PresentingScreenCoordinatorComponent {
        presentingComponent
    }

    @MainActor
    func destroyComponent() async {
        await pop()
    }
}

public class SequenceCoordinatorComponent: ObservableObject, Component {

    public let navigationId: CoordinatorID = CoordinatorID()

    public enum ChildCoordinator {
        case sequence(SequenceCoordinatorEntity)
        case screen(ScreenCoordinatorEntity)

        public func getID() -> CoordinatorID {
            return switch self {
            case .sequence(let entity):
                entity.navigationId
            case .screen(let entity):
                entity.navigationId
            }
        }
    }

    struct Parent {
        weak var stack: StackCoordinatorComponent?
        weak var sequence: SequenceCoordinatorComponent?

        init(stack: StackCoordinatorComponent?) {
            self.stack = stack
            self.sequence = nil
        }

        init(sequence: SequenceCoordinatorComponent?) {
            self.stack = nil
            self.sequence = sequence
        }
    }

    var parent: Parent?
    var childCoordinators: [ChildCoordinator] = []

    public init() {
        self.childCoordinators = []
    }

    public init(coordinators: [ChildCoordinator]) {
        self.childCoordinators = coordinators
    }

    @MainActor
    public func push(screen: ScreenCoordinatorEntity) async {
        childCoordinators.append(.screen(screen))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func push(screens: [ScreenCoordinatorEntity]) async {
        for screen in screens {
            childCoordinators.append(.screen(screen))
        }
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func push(sequence: SequenceCoordinatorEntity) async {
        sequence.navigationComponent.parent = Parent(sequence: self)
        childCoordinators.append(.sequence(sequence))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func pop(count: Int = 1) async {
        let dropCount = childCoordinators.count - count
        guard dropCount > 0 else { return }
        let removedCoordinatorIDs = childCoordinators.dropFirst(dropCount).map { $0.getID() }
        await sendEventToParent(event: .removeCoordinatorsNeeded(removedCoordinatorIDs))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func popToFirst() async {
        let count = childCoordinators.count - 1
        await pop(count: count)
    }

    @MainActor
    public func pop(id: CoordinatorID) async {
        guard childCoordinators.contains(where: { $0.getID() == id }) else { return }
        await sendEventToParent(event: .removeCoordinatorsNeeded([id]))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func pop(sequence: SequenceCoordinatorEntity) async {
        await pop(id: sequence.navigationId)
    }

    @MainActor
    public func pop(screen: ScreenCoordinatorEntity) async {
        await pop(id: screen.navigationId)
    }

    @MainActor
    public func set(screen: ScreenCoordinatorEntity) async {
        await set(screens: [screen])
    }

    @MainActor
    public func set(screens: [ScreenCoordinatorEntity]) async {
        let removedCoordinatorIDs = childCoordinators.map { $0.getID() }
        for screen in screens {
            childCoordinators.append(.screen(screen))
        }
        await sendEventToParent(event: .removeCoordinatorsNeeded(removedCoordinatorIDs))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    @MainActor
    public func set(sequence: SequenceCoordinatorEntity) async {
        sequence.navigationComponent.parent = Parent(sequence: self)
        let removedCoordinatorIDs = childCoordinators.map { $0.getID() }
        childCoordinators.append(.sequence(sequence))
        await sendEventToParent(event: .removeCoordinatorsNeeded(removedCoordinatorIDs))
        await sendEventToParent(event: .navigationPathUpdateNeeded)
    }

    public func count() -> Int {
        childCoordinators.count
    }

    public func childrenIDs() -> [CoordinatorID] {
        childCoordinators.map { $0.getID() }
    }

    public func children() -> [ChildCoordinator] {
        childCoordinators
    }

    /// Removes the unused children coordinators that are not in the path recursively.
    ///
    /// Returns true if the coordinator still contains at least one child in the path
    @MainActor
    func removeUnusedCoordinators(path: String) async -> Bool {
        var idx = childCoordinators.count
        var childInPath = false
        while idx > 0 {
            var currentChildInPath = false
            let coordinator = childCoordinators[idx - 1]

            switch coordinator {
            case .screen(let screenCoordinator):
                if path.range(of: screenCoordinator.navigationId.uuidString) != nil {
                    currentChildInPath = true
                }

                if currentChildInPath {
                    childInPath = true
                } else {
                    removeCoordinator(id: screenCoordinator.navigationId)
                    await screenCoordinator.navigationComponent.destroyComponent()
                }
            case .sequence(let sequenceCoordinator):
                if await sequenceCoordinator.navigationComponent.removeUnusedCoordinators(path: path) {
                    currentChildInPath = true
                }

                if currentChildInPath {
                    childInPath = true
                } else {
                    removeCoordinator(id: sequenceCoordinator.navigationId)
                    await sequenceCoordinator.navigationComponent.destroyComponent()
                }
            }
            idx = idx - 1
        }
        return childInPath
    }

    /// Removes specified children coordinators recursively
    ///
    /// Returns true if the coordinator still contains at least one child in the path
    @MainActor
    func removeCoordinators(iDs: [CoordinatorID]) async -> Bool {
        var idx = childCoordinators.count
        var allChildrenAreDestroyed = true
        while idx > 0 {
            let coordinator = childCoordinators[idx - 1]
            switch coordinator {
            case .screen(let screenCoordinator):
                if iDs.contains(where: { $0 == screenCoordinator.navigationId }) {
                    await screenCoordinator.navigationComponent.destroyComponent()
                    childCoordinators.removeAll(where: { $0.getID() == screenCoordinator.navigationId })
                } else {
                    allChildrenAreDestroyed = false
                }
            case .sequence(let sequenceCoordinator):
                let sequenceFound = iDs.contains(where: { $0 == sequenceCoordinator.navigationId })
                let sequenceWithoutChildren = await sequenceCoordinator.navigationComponent.removeCoordinators(iDs: iDs)

                if sequenceFound || sequenceWithoutChildren {
                    await sequenceCoordinator.navigationComponent.destroyComponent()
                    childCoordinators.removeAll(where: { $0.getID() == sequenceCoordinator.navigationId })
                } else {
                    allChildrenAreDestroyed = false
                }
            }
            idx = idx - 1
        }
        return allChildrenAreDestroyed
    }

    @MainActor
    func sendEventToParent(event: Event) async {
        if let parentStack = parent?.stack {
            await parentStack.eventReceived(event: event)
        } else if let parentSequence = parent?.sequence {
            await parentSequence.sendEventToParent(event: event)
        }
    }

    func removeCoordinator(id: CoordinatorID) {
        childCoordinators.removeAll { $0.getID() == id }
    }

    @MainActor
    func destroyComponent() async {
        //        print("Sequence destroyed")
        parent = nil
        for child in childCoordinators {
            switch child {
            case .sequence(let sequenceCoordinatorEntity):
                await sequenceCoordinatorEntity.navigationComponent.destroyComponent()
            case .screen(let screenCoordinatorEntity):
                await screenCoordinatorEntity.navigationComponent.destroyComponent()
            }
        }
        childCoordinators = []
    }
}

public extension NavigationPath {
    func getPathRepresentation() -> String {
        if let codable = self.codable,
           let data = try? JSONEncoder().encode(codable) {
            return String(decoding: data, as: UTF8.self)
        } else {
            return ""
        }
    }
}

public extension View {
    func toAnyView() -> AnyView {
        AnyView(self)
    }
}

public struct NavigationTree {
    public enum Node {
        case stack(StackCoordinatorComponent)
        case sequence(SequenceCoordinatorComponent)
        case screen(ScreenCoordinatorComponent)

        public init(_ component: Component) {
            if let stackCoordinator = component as? StackCoordinatorComponent {
                self = .stack(stackCoordinator)
            } else if let sequenceCoordinator = component as? SequenceCoordinatorComponent {
                self = .sequence(sequenceCoordinator)
            } else if let screenCoordinator = component as? ScreenCoordinatorComponent {
                self = .screen(screenCoordinator)
            } else {
                fatalError("Unknown Coordinator Node")
            }
        }

        public var navigationId: CoordinatorID {
            return switch self {
            case .stack(let component):
                component.navigationId
            case .sequence(let component):
                component.navigationId
            case .screen(let component):
                component.navigationId
            }
        }

        public var component: Component {
            return switch self {
            case .stack(let component):
                component
            case .sequence(let component):
                component
            case .screen(let component):
                component
            }
        }
    }

    static func getTreeRecursive(from: Node) -> [Node] {
        var newTree: [Node] = []
        switch from {
        case .stack(let stack):
            if let sequenceCoordinator = stack.sequenceCoordinator {
                newTree.append(contentsOf: getTreeRecursive(from: Node(sequenceCoordinator.navigationComponent)))
            }
        case .sequence(let sequence):
            for child in sequence.childCoordinators {
                switch child {
                case .sequence(let childSequence):
                    newTree.append(contentsOf: getTreeRecursive(from: Node(childSequence.navigationComponent)))
                case .screen(let screen):
                    newTree.append(Node(screen.navigationComponent))
                }
            }
        case .screen(let screen):
            newTree.append(Node(screen))
        }

        return newTree
    }

    static func getIDTreeRecursive(from: Node) -> [CoordinatorID] {
        let tree = getTreeRecursive(from: from)
        return tree.map { $0.navigationId }
    }

    static func getComponent(from: Node, navigationId: CoordinatorID) -> Component? {
        let tree = getTreeRecursive(from: from)
        return tree.first { $0.navigationId == navigationId }?.component
    }

    static func getFirstComponent(from: Node) -> Component? {
        let tree = getTreeRecursive(from: from)
        return tree.first?.component
    }

    static func getRootStackParent(from: Node) -> StackCoordinatorComponent? {
        switch from {
        case .stack(let stackCoordinatorComponent):
            return stackCoordinatorComponent
        case .sequence(let sequenceCoordinatorComponent):
            if let parent = sequenceCoordinatorComponent.parent {
                if let parentStack = parent.stack {
                    return getRootStackParent(from: Node(parentStack))
                } else if let parentSequence = parent.sequence {
                    return getRootStackParent(from: Node(parentSequence))
                } else {
                    return nil
                }
            } else {
                return nil
            }
        case .screen:
            return nil
        }
    }
}

/// Use this coordinator to initialize a ViewEntity using async/await.
public class AsyncViewCoordinator<LoadingViewType: View>: ObservableObject {

    @Published var loadedCoordinator: ViewEntity?
    @Published var loadingView: LoadingViewType?

    public init(loadingView: LoadingViewType, closure: @escaping () async -> ViewEntity) {
        self.loadingView = loadingView
        Task { @MainActor in
            self.loadedCoordinator = await closure()
            self.loadingView = nil
        }
    }

    public func getView() -> AnyView {
        ContentView(coordinator: self).toAnyView()
    }

    struct ContentView: View {
        @ObservedObject var coordinator: AsyncViewCoordinator<LoadingViewType>

        var body: some View {
            if let loadedCoordinator = coordinator.loadedCoordinator {
                loadedCoordinator.getView()
            } else if let loadingView = coordinator.loadingView {
                loadingView
            }
        }
    }
}

public class DefaultStackCoordinator: StackCoordinatorEntity {
    public let navigationComponent: StackCoordinatorComponent = StackCoordinatorComponent()

    public init() {}

    public init(sequenceCoordinator: SequenceCoordinatorEntity) async {
        await navigationComponent.set(sequence: sequenceCoordinator)
    }
}

public class DefaultSequenceCoordinator: SequenceCoordinatorEntity {
    public let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()

    public init() {}

    public init(screenCoordinator: ScreenCoordinatorEntity) async {
        await navigationComponent.set(screen: screenCoordinator)
    }

    public init(screenCoordinators: [ScreenCoordinatorEntity]) async {
        await navigationComponent.set(screens: screenCoordinators)
    }

    public init(sequenceCoordinator: SequenceCoordinatorEntity) async {
        await navigationComponent.set(sequence: sequenceCoordinator)
    }
}

public class DefaultScreenCoordinator: ScreenCoordinatorEntity {
    public let navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()

    public init() {}

    public init(view: some View) {
        navigationComponent.setView(view)
    }
}
