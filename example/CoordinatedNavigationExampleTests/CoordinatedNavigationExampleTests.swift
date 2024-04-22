import XCTest
@testable import CoordinatedNavigation
@testable import CoordinatedNavigationExample
import SwiftUI

final class CoordinatedNavigationExampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    @MainActor
//    func testDeallocation() async {
//        var screenCoordinator1: OnboardingScreenCoordinator? = OnboardingScreenCoordinator()
//        var screenCoordinator2: OnboardingScreenCoordinator? = OnboardingScreenCoordinator()
//        weak var weakScreenCoordinator1: OnboardingScreenCoordinator? = screenCoordinator1
//        weak var weakScreenCoordinator2: OnboardingScreenCoordinator? = screenCoordinator2
//
//        var sequenceCoordinator: RootSequenceCoordinator? = await RootSequenceCoordinator(screens: [screenCoordinator1!, screenCoordinator2!])
//        weak var weakSequenceCoordinator: RootSequenceCoordinator? = sequenceCoordinator
//
//        var rootCoordinator: DefaultStackCoordinator? = await DefaultStackCoordinator(sequenceCoordinator: sequenceCoordinator!)
//        weak var weakRootCoordinator: DefaultStackCoordinator? = rootCoordinator
//
//        sequenceCoordinator = nil
//        screenCoordinator1 = nil
//        screenCoordinator2 = nil
//        _ = rootCoordinator
//
//        XCTAssertNotNil(weakRootCoordinator)
//        XCTAssertNotNil(weakSequenceCoordinator)
//        XCTAssertNotNil(weakScreenCoordinator1)
//        XCTAssertNotNil(weakScreenCoordinator2)
//
//        await rootCoordinator!.navigationComponent.pop()
//        print(rootCoordinator!.navigationComponent.navigationPath.getPathRepresentation())
//        rootCoordinator = nil
//
//        try? await Task.sleep(for: .seconds(2))
//
//        _ = await Task {
//            XCTAssertNil(weakRootCoordinator)
//            XCTAssertNil(weakSequenceCoordinator)
//            XCTAssertNil(weakScreenCoordinator1)
//            XCTAssertNil(weakScreenCoordinator2)
//        }.result
//    }
//
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

//    class RootStackCoordinator: StackCoordinatorEntity {
//        let navigationComponent: StackCoordinatorComponent = StackCoordinatorComponent()
//
//        init(sequence: RootSequenceCoordinator) {
//
//            navigationComponent.setRootView(ExampleA.SplashScreen())
//
//            Task { @MainActor in
//                try await Task.sleep(for: .seconds(2))
//                await navigationComponent.set(sequence: sequence)
//            }
//        }
//    }
//
//    class RootSequenceCoordinator: SequenceCoordinatorEntity {
//        let navigationComponent: SequenceCoordinatorComponent = SequenceCoordinatorComponent()
//
//        init(screens: [OnboardingScreenCoordinator]) async {
//            for screen in screens {
//                await navigationComponent.push(screen: screen)
//            }
//        }
//    }
//
//    class OnboardingScreenCoordinator: ScreenCoordinatorEntity {
//        let navigationComponent: ScreenCoordinatorComponent = ScreenCoordinatorComponent()
//
//        init() {
//            navigationComponent.setView(Text("Onboarding"))
//        }
//    }
}
