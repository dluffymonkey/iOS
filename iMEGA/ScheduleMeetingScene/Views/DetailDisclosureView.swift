
import SwiftUI

struct DetailDisclosureView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        static let disclosureOpacity: CGFloat = 0.6
        static let discolureIndicator = "chevron.right"
    }
    
    let text: String
    let detail: String?
    let action: (() -> Void)

    var body: some View {
        VStack {
            HStack {
                Text(text)
                    .font(.body)
                Spacer()
                if let detail {
                    Text(detail)
                        .foregroundColor(colorScheme == .dark ? Color(UIColor.mnz_grayEBEBF5()).opacity(Constants.disclosureOpacity) : Color(UIColor.mnz_gray3C3C43()).opacity(Constants.disclosureOpacity))
                }
                Image(systemName: Constants.discolureIndicator)
                    .foregroundColor(.gray.opacity(Constants.disclosureOpacity))
                    .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
            }
            .padding(.horizontal)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
