import SwiftUI

struct PhotoDayCard: View {
    @StateObject var viewModel: PhotoDayCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel, badgeTitle: viewModel.badgeTitle) {
            if #available(iOS 15.0, *) {
                Text(viewModel.attributedTitle)
            } else {
                Text(viewModel.title)
                    .font(.title2.bold())
            }
        }
    }
}

extension PhotoDayCard: Equatable {
    static func == (lhs: PhotoDayCard, rhs: PhotoDayCard) -> Bool {
        true // we are taking over the update of the view
    }
}
