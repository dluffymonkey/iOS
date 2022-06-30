import UIKit
import CoreServices

extension CloudDriveViewController: CloudDriveContextMenuDelegate {
    //MARK: - Context Menus configuration
    func contextMenuConfiguration() -> CMConfigEntity? {
        guard let parentNode = parentNode else { return nil }
        
        if parentNode.isFolder(),
           displayMode == .rubbishBin,
           parentNode.handle != MEGASdkManager.sharedMEGASdk().rubbishNode?.handle {
            return CMConfigEntity(menuType: .rubbishBin,
                                  isRubbishBinFolder: true,
                                  isRestorable: parentNode.mnz_isRestorable())
        } else {
            let parentNodeAccessLevel = MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode)
            let isIncomingSharedRootChild = parentNodeAccessLevel != .accessOwner && MEGASdkManager.sharedMEGASdk().parentNode(for: parentNode) == nil
            
            if #available(iOS 14.0, *) {
                return CMConfigEntity(menuType: .display,
                                      viewMode: isListViewModeSelected() ? ViewModePreference.list : ViewModePreference.thumbnail,
                                      accessLevel: parentNodeAccessLevel,
                                      sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: parentNode)),
                                      isAFolder: parentNode.type != .root,
                                      isRubbishBinFolder: displayMode == .rubbishBin,
                                      isIncomingShareChild: isIncomingSharedRootChild,
                                      showMediaDiscovery: shouldShowMediaDiscovery())
            } else {
                return CMConfigEntity(menuType: .display,
                                      viewMode: isListViewModeSelected() ? ViewModePreference.list : ViewModePreference.thumbnail,
                                      accessLevel: parentNodeAccessLevel,
                                      sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: parentNode)),
                                      isAFolder: parentNode.type != .root,
                                      isRubbishBinFolder: displayMode == .rubbishBin,
                                      isIncomingShareChild: isIncomingSharedRootChild)
            }
        }
    }
    
    func uploadAddMenuConfiguration() -> CMConfigEntity? {
        CMConfigEntity(menuType: .uploadAdd)
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(displayMenuDelegate: self,
                                                quickFolderActionsMenuDelegate: self,
                                                uploadAddMenuDelegate: self,
                                                rubbishBinMenuDelegate: self,
                                                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository()))
    }
    
    @objc func setNavigationBarButtons() {
        if #available(iOS 14.0, *) {
            guard let menuConfig = contextMenuConfiguration() else { return }
            contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                                   menu: contextMenuManager?.contextMenu(with: menuConfig))
        } else {
            contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, style: .plain, target: self, action: #selector(presentActionSheet(sender:)))
        }
        
        if displayMode != .rubbishBin,
            let parentNode = parentNode,
            MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode) != .accessRead {
            if #available(iOS 14.0, *) {
                guard let menuConfig = uploadAddMenuConfiguration() else { return }
                uploadAddBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image,
                                                         menu: contextMenuManager?.contextMenu(with: menuConfig))
            } else {
                uploadAddBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image, style: .plain, target: self, action: #selector(presentActionSheet(sender:)))
            }
            
            navigationItem.rightBarButtonItems = [contextBarButtonItem, uploadAddBarButtonItem]
        } else {
            navigationItem.rightBarButtonItems = [contextBarButtonItem]
        }
    }
    
    @objc private func presentActionSheet(sender: Any) {
        guard let barButtonItem = sender as? UIBarButtonItem,
              let menuConfig = barButtonItem == contextBarButtonItem ? contextMenuConfiguration() : uploadAddMenuConfiguration(),
              let actions = contextMenuManager?.actionSheetActions(with: menuConfig) else { return }
        presentActionSheet(actions: actions)
    }
    
    @objc func presentActionSheet(actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions,
                                                      headerTitle: nil,
                                                      dismissCompletion: nil,
                                                      sender: nil)

        self.present(actionSheetVC, animated: true)
    }
    
    //MARK: - CloudDriveContextMenuDelegate functions
    func displayMenu(didSelect action: DisplayAction, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            guard let enableEditing = cdTableView?.tableView?.isEditing ?? cdCollectionView?.collectionView?.allowsMultipleSelection else { return }
            setEditMode(!enableEditing)
        case .thumbnailView, .listView:
            changeViewModePreference()
        case .clearRubbishBin:
            let alertController = UIAlertController(title: Strings.Localizable.emptyRubbishBinAlertTitle, message: nil, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
            alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default) { _ in
                MEGASdkManager.sharedMEGASdk().cleanRubbishBin()
            })
            
            UIApplication.mnz_visibleViewController().present(alertController, animated: true, completion: nil)
        case .mediaDiscovery:
            if #available(iOS 14, *) {
                guard let parentNode = parentNode else { return }
                MediaDiscoveryRouter(viewController: self, parentNode: parentNode).start()
            }
        default: break
        }
        
        if #available(iOS 14, *), needToRefreshMenu {
            setNavigationBarButtons()
        }
    }
    
    func quickFolderActionsMenu(didSelect action: QuickFolderAction) {
        guard let parentNode = parentNode else { return }
        
        switch action {
        case .info:
            showNodeInfo(parentNode)
        case .download:
            download([parentNode])
        case .shareLink:
            presentGetLinkVC(for: [parentNode])
        case .shareFolder:
            showShareFolderForNodes([parentNode])
        case .rename:
            parentNode.mnz_renameNode(in: self) { [weak self] request in
                self?.navigationItem.title = request.name
            }
        case .leaveSharing:
            parentNode.mnz_leaveSharing(in: self)
            navigationController?.popViewController(animated: true)
        case .copy:
            parentNode.mnz_copy(in: self)
        }
    }
    
    func uploadAddMenu(didSelect action: UploadAddAction) {
        switch action {
        case .scanDocument:
            presentScanDocument()
        case .newFolder:
            createNewFolderAction()
        case .newTextFile:
            guard let parentNode = parentNode else { return }
            CreateTextFileAlertViewRouter(presenter: navigationController, parentHandle: parentNode.handle).start()
        case .chooseFromPhotos:
            showImagePicker(for: .photoLibrary)
        case .capture:
            DevicePermissionsHelper.videoPermission { [weak self] granted in
                if granted {
                    DevicePermissionsHelper.photosPermission { granted in
                        if !granted {
                            UserDefaults.standard.set(false, forKey: "isSaveMediaCapturedToGalleryEnabled")
                        }
                        
                        self?.showImagePicker(for: .camera)
                    }
                } else {
                    DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
                }
            }
        case .importFrom:
            let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeContent as String,
                                                                                kUTTypeData as String,
                                                                                kUTTypePackage as String,
                                                                                "com.apple.iwork.pages.pages",
                                                                                "com.apple.iwork.numbers.numbers",
                                                                                "com.apple.iwork.keynote.key"],
                                                                in: .import)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = true
            documentPicker.popoverPresentationController?.barButtonItem = contextBarButtonItem
            present(documentPicker, animated: true)
        }
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        Helper.save(sortType.megaSortOrderType, for: parentNode)
        nodesSortTypeHasChanged()
        if #available(iOS 14, *) {
            setNavigationBarButtons()
        }
    }
    
    func rubbishBinMenu(didSelect action: RubbishBinAction) {
        guard let parentNode = parentNode else { return }
        
        switch action {
        case .restore:
            parentNode.mnz_restore()
            navigationController?.popViewController(animated: true)
        case .info:
            showNodeInfo(parentNode)
        case .versions:
            parentNode.mnz_showVersions(in: self)
        case .remove:
            parentNode.mnz_remove(in: self) { [weak self] shouldRemove in
                if shouldRemove {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    @objc func presentUploadOptions() {
        if contextMenuManager == nil { configureContextMenuManager() }
        
        guard let config = uploadAddMenuConfiguration(),
              let actions = contextMenuManager?.actionSheetActions(with: config) else { return }
        
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}