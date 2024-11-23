import Foundation
import CoordinatedNavigation
import SwiftUI

class TestStorage {
    static var stackCount: Int = 0
    static var sequenceCount: Int = 0
    static var screenCount: Int = 0
}

public enum TestStep: String, CaseIterable {
    case pushScreen
    case pushSequence
    case pop
    case presentScreen
    case presentStack
    case dismiss
    case parent
}

public class TestStackCoordinator: StackCoordinator {
    public let navigationComponent = StackCoordinatorComponent()
    var output: (([TestStep]) -> Void)?

    public init() {
        TestStorage.stackCount += 1
    }

    @MainActor
    public func executeSteps(_ steps: [TestStep]) async {
        var idx = 0
        var finished = false
        while idx < steps.count, !finished {
            let step = steps[idx]
            let consumedSteps = Array(steps[idx ..< steps.count].dropFirst())
            switch step {
            case .parent:
                self.output?(consumedSteps)
                finished = true
            case .presentScreen, .presentStack, .dismiss, .pushScreen, .pop:
                print("Can't do this step: \(step)")
                finished = true
            case .pushSequence:
                let coordinator = TestSequenceCoordinator()
                coordinator.output = { [weak self] s in Task { await self?.executeSteps(s) }}
                await coordinator.executeSteps(consumedSteps)
                await self.navigationComponent.set(sequence: coordinator)
                finished = true
            }
            idx += 1
        }
    }
}

public class TestSequenceCoordinator: SequenceCoordinator {
    public let navigationComponent = SequenceCoordinatorComponent()
    var output: (([TestStep]) -> Void)?

    public init() {
        TestStorage.sequenceCount += 1
    }

    @MainActor
    public func executeSteps(_ steps: [TestStep]) async {
        var idx = 0
        var finished = false
        while idx < steps.count, !finished {
            let step = steps[idx]
            let consumedSteps = Array(steps[idx ..< steps.count].dropFirst())
            switch step {
            case .parent:
                self.output?(consumedSteps)
                finished = true
            case .presentScreen, .presentStack, .dismiss:
                var newSteps = consumedSteps
                newSteps.insert(step, at: 0)
                self.output?(newSteps)
                finished = true
            case .pushScreen:
                let coordinator = TestScreenCoordinator()
                coordinator.output = { [weak self] s in Task { await self?.executeSteps(s) }}
                await coordinator.executeSteps(consumedSteps)
                await self.navigationComponent.push(screen: coordinator)
                finished = true
            case .pushSequence:
                let coordinator = TestSequenceCoordinator()
                coordinator.output = { [weak self] s in Task { await self?.executeSteps(s) }}
                await coordinator.executeSteps(consumedSteps)
                await self.navigationComponent.push(sequence: coordinator)
                finished = true
            case .pop:
                await self.navigationComponent.pop()
            }
            idx += 1
        }
    }
}

public class TestScreenCoordinator: ScreenCoordinator {
    public let navigationComponent = ScreenCoordinatorComponent()
    let name: String
    var output: (([TestStep]) -> Void)?

    public init() {
        TestStorage.screenCount += 1
        name = "\(TestStorage.screenCount)"
        self.navigationComponent.setView(
            TestView(name: name, output: { steps in
                Task { await self.executeSteps(steps) }
            })
        )
    }

    @MainActor
    public func executeSteps(_ steps: [TestStep]) async {
        var idx = 0
        var finished = false
        while idx < steps.count, !finished {
            let step = steps[idx]
            let consumedSteps = Array(steps[idx ..< steps.count].dropFirst())
            switch step {
            case .parent:
                self.output?(consumedSteps)
                finished = true
            case .pushScreen, .pushSequence, .pop:
                var newSteps = consumedSteps
                newSteps.insert(step, at: 0)
                self.output?(newSteps)
                finished = true
            case .presentScreen:
                let coordinator = TestScreenCoordinator()
                coordinator.output = { [weak self] s in Task { await self?.executeSteps(s) }}
                await coordinator.executeSteps(consumedSteps)
                await self.navigationComponent.presentingComponent.present(
                    screen: coordinator,
                    mode: .sheet
                )
                finished = true
            case .presentStack:
                let coordinator = TestStackCoordinator()
                coordinator.output = { [weak self] s in Task { await self?.executeSteps(s) }}
                await coordinator.executeSteps(consumedSteps)
                await self.navigationComponent.presentingComponent.present(
                    stack: coordinator,
                    mode: .sheet
                )
                finished = true
            case .dismiss:
                await self.navigationComponent.presentingComponent.dismiss()
            }
            idx += 1
        }
    }
}

struct TestView: View {

    @State var steps: [TestStep] = []
    let name: String
    var output: (([TestStep]) -> Void)

    var body: some View {
        VStack{
            Text("Screen Name: \(TestStorage.screenCount)")

            ForEach(TestStep.allCases,id: \.rawValue) { step in
                Button {
                    steps.append(step)
                } label: {
                    Text(step.rawValue)
                }
            }

            Button {
                output(steps)
                steps.removeAll()
            } label: {
                Text("COMMIT")
            }

            Button {
                steps = []
            } label: {
                Text("RESET")
            }

            Spacer()

            Text(steps.map{ $0.rawValue }.joined(separator: ", "))
        }
    }
}
