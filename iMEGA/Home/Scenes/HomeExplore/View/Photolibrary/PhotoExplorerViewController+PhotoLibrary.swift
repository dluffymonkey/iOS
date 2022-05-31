import SwiftUI

@available(iOS 14.0, *)
extension PhotosExplorerViewController: PhotoLibraryProvider {
    func showNavigationRightBarButton(_ show: Bool) {
        navigationItem.rightBarButtonItem = show ? editBarButtonItem : nil
    }
        
    func didSelectedPhotoCountChange(_ count: Int) {
        updateNavigationTitle(withSelectedPhotoCount: count)
        configureToolbarButtons()
    }
    
    func setupPhotoLibrarySubscriptions() {
        photoLibraryPublisher.subscribeToSelectedModeChange { [weak self] in
            self?.showNavigationRightBarButton($0 == .all && self?.photoLibraryContentViewModel.library.isEmpty == false)
        }
        
        photoLibraryPublisher.subscribeToSelectedPhotosChange { [weak self] in
            self?.selection.setSelectedNodes(Array($0.values))
            self?.didSelectedPhotoCountChange($0.count)
        }
    }
    
    func hideNavigationEditBarButton(_ hide: Bool) {
        editBarButtonItem.isEnabled = !hide
        navigationItem.rightBarButtonItem = hide ? nil : editBarButtonItem
    }
}
