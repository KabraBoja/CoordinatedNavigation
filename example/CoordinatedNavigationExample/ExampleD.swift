import Foundation
import CoordinatedNavigation
import SwiftUI

struct ExampleD {

    public static func createAPlainTutorialScreenCoordinator() -> ScreenCoordinatorEntity {

        struct TutorialPlainView: View {

            @State var likeCount: Int = 0

            var body: some View {
                Text("Tutorial Plain View")
                    .font(.title2)
                Text("This is just an example tutorial screen")
                Text("Like count: \(likeCount)")
                Button {
                    likeCount = likeCount + 1
                } label: {
                    Text("Like!")
                }
            }
        }

        return DefaultScreenCoordinator(view: TutorialPlainView())
    }

    public static func createACustomTutorialScreenCoordinator(onNextPressed: @escaping () -> Void) -> ScreenCoordinatorEntity {

        class CustomTutorialViewModel: ObservableObject {
            @Published var title: String
            @Published var nextTitle: String
            let onNextPressed: () -> Void

            init(title: String, nextTitle: String, onNextPressed: @escaping () -> Void) {
                self.title = title
                self.nextTitle = nextTitle
                self.onNextPressed = onNextPressed
            }
        }

        struct CustomTutorialView: View {

            @ObservedObject var viewModel: CustomTutorialViewModel

            var body: some View {
                Text(viewModel.title)
                    .font(.title2)
                Button {
                    viewModel.onNextPressed()
                } label: {
                    Text(viewModel.nextTitle)
                        .font(.callout)
                }
            }
        }

        let viewModel = CustomTutorialViewModel(title: "Custom Tutorial View", nextTitle: "Next", onNextPressed: onNextPressed)
        return CustomTutorialView(viewModel: viewModel).toScreenCoordinator()
    }
}
