# What is Coordinated Navigation?

Coordinated Navigation is a Swift library that enables navigating between screens using a navigation tree structure where every node doesn’t need to know each other.

Implemented in SwiftUI (iOS 16 Navigation Stack) uses a Coordinator Pattern approach.

## Why?

The coordinator pattern establishes who is responsible of navigating in a very clear way.

As a developer I’ve faced many projects where this responsibility is not clear enough.

The Tree Structure forces the coordinators to always be responsible of their own funnel and their direct children. This helps us to follow the single responsibility principle.

## How?

- Using Coordinator Components
   - Stack
   - Sequence
   - Screen
- Composition over inheritance
- Async / Await
- Presentation
- AnyView

### Stack Coordinator
A Stack Coordinator coordinates a navigation stack. It's used as the entry point of the app or a modal presentation.

Contains a NavigationStack view (Tree structure root).
Transitions between a root View and a Sequence.
Can only set/pop a Sequence.


Example: The root view could be an splash screen. As soon as the app loads some needed stuff, the Stack Coordinator sets the first Sequence Coordinator.

### Sequence Coordinator
A Sequence Coordinator manages the transitions for an specific funnel.
Contains two types of children:

- Sequence Coordinators (tree structure)
- Screen Coordinators (leaf nodes)

Also

- Navigates through a sequence of children nodes
- Can only push/pop/set children nodes

Example: A Sequence (Search funnel) could coordinate between the Suggest / List / Detail screens. Each child doesn't know each other.

### Screen Coordinator

A Screen Coordinator simply represents a SwiftUI view.

- Contains a SwiftUI view (AnyView).
- Leaf node.

Why use a coordinator for a simple screen (view)?

- We avoid the view knowing about Domain scope.
- The coordinator could be in charge of holding a reference to a Presenter or a ViewModel. Or even be used as the ObservableObject.
- Serves as a good abstraction when working with modules/service locators.

## Next Steps?

- Upload an example project (WIP)
- Try to use any View instead of AnyView.
- Add routes and builder pattern (typed navigation).
- Modal Presentation could also happen from the Stack coordinator.
- Explore if I can merge the Stack with the Sequence.
- Does it makes sense to have a RootView in the Stack? Maybe use an Screen coordinator directly.