
import SwiftUI

struct ScheduleMeetingCreationNameView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    var appearFocused: Bool

    var body: some View {
        VStack {
            Divider()
            if #available(iOS 15.0, *) {
                FocusableTextFieldView(text: $viewModel.meetingName, appearFocused: appearFocused)
            } else {
                TextFieldView(text: $viewModel.meetingName)
            }
            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
    }
}
