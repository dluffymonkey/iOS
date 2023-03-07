import FileProvider
import MEGADomain

final class FileProviderExtension: NSFileProviderExtension {
    private let semaphore = DispatchSemaphore(value: 0)
    
    private lazy var credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)
    private lazy var nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
    private lazy var transferUseCase = TransferUseCase(repo: TransferRepository.newRepo)
    
    override init() {
        super.init()
#if DEBUG
        MEGASdk.setLogLevel(.max)
#endif
        MEGASdk.setLogToConsole(true)
        login()
    }
    
    // MARK: - Working with items and persistent identifiers
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        var identifier: String
        // This is a bit tricky. As an identifier, we use the "path" in MEGA ex: /folder/subfolder/file,
        // We create "placeholders" and files/folders in NSFileProviderManager.default.documentStorageURL (+ identifier) appending the identifier (path in MEGA)
        // This method is called from different places and the URL may contain "/private" or not, documentStorageURL includes "/private": file:///private/var/mobile/Containers/Shared/AppGroup/E987FA27-C16B-424A-8148-865F8AE2E932/File%20Provider%20Storage/
        // When calling it from itemChanged, url is similar to (it doesn't include "/private"): file:///var/mobile/Containers/Shared/AppGroup/2F61E5F1-174B-434D-A51C-0A7019C3AD8D/File%20Provider%20Storage/
        // When calling it from providingPlaceholder or startProvidingItem url includes "/private": file:///private/var/mobile/Containers/Shared/AppGroup/2F61E5F1-174B-434D-A51C-0A7019C3AD8D/File%20Provider%20Storage/
        // This is the reason of the following code, getting the correct identifier
        if url.path().contains("/private") {
            identifier = url.path.replacingOccurrences(of: NSFileProviderManager.default.documentStorageURL.path, with: "")
        } else {
            identifier = url.path.replacingOccurrences(of: NSFileProviderManager.default.documentStorageURL.path.replacingOccurrences(of: "/private", with: ""), with: "")
        }
        return NSFileProviderItemIdentifier(identifier)
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        let url: URL? = NSFileProviderManager.default.documentStorageURL
            .appending(component: identifier.rawValue.dropFirst())
        return url
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        guard let node = node(for: identifier) else {
            throw NSError.fileProviderErrorForNonExistentItem(withIdentifier: identifier)
        }
        return FileProviderItem(node: node)
    }
    
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> NSFileProviderEnumerator {
        guard credentialUseCase.hasSession() else {
            throw NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue)
        }
        
        guard !credentialUseCase.isPasscodeEnabled() else {
            throw NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue, userInfo: [PickerConstant.passcodeEnabled : true])
        }
        
        if MEGASdk.shared.isLoggedIn() == 0 {
            semaphore.wait()
        }
        let enumerator = FileProviderEnumerator(identifier: containerItemIdentifier)
        return enumerator
    }
    
    // MARK: - Managing shared files
    
    override func providePlaceholder(at url: URL) async throws {
        guard let identifier = persistentIdentifierForItem(at: url) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let fileProviderItem = try item(for: identifier)
        let placecholderDirectoryUrl = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: placecholderDirectoryUrl.path) {
            try FileManager.default.createDirectory(at: placecholderDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        }
        let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
        try NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: fileProviderItem)
    }
    
    override func startProvidingItem(at url: URL) async throws {
        guard let identifier = persistentIdentifierForItem(at: url),
              let node = node(for: identifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            _ = try await transferUseCase.download(node: node, to: url)
        }
    }
    
    override func itemChanged(at url: URL) {
        guard let identifier = persistentIdentifierForItem(at: url),
              let node = node(for: identifier),
              FileManager.default.fileExists(atPath: url.path),
              let parentNode = MEGASdk.shared.node(forHandle: node.parentHandle) else {
            return
        }
        
        Task {
            let fileProviderItem = try item(for: identifier)
            _ = try await transferUseCase.uploadFile(at: url, to: parentNode.toNodeEntity(), startHandler: {  _ in
                NSFileProviderManager.default.signalEnumerator(for: identifier) { error in
                    if let error {
                        MEGALogError("Error signaling item: \(error)")
                    }
                }
                NSFileProviderManager.default.signalEnumerator(for: fileProviderItem.parentItemIdentifier) { error in
                    if let error {
                        MEGALogError("Error signaling item: \(error)")
                    }
                }
            })
            
            NSFileProviderManager.default.signalEnumerator(for: identifier) { error in
                if let error {
                    MEGALogError("Error signaling item: \(error)")
                }
            }
            NSFileProviderManager.default.signalEnumerator(for: fileProviderItem.parentItemIdentifier) { error in
                if let error {
                    MEGALogError("Error signaling item: \(error)")
                }
            }
        }
    }
    
    override func stopProvidingItem(at url: URL) {
        MEGALogDebug("[Picker] stopProvidingItem at \(url)")
    }
    
    
    // MARK: - Handling Actions
    
    override func createDirectory(withName directoryName: String, inParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier) async throws -> NSFileProviderItem {
        guard let parentNode = node(for: parentItemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }

        let node = try await nodeActionUseCase.createFolder(name: directoryName, parent: parentNode)
        return FileProviderItem(node: node)
    }
    
    override func renameItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toName itemName: String) async throws -> NSFileProviderItem {
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let renamedNode = try await nodeActionUseCase.rename(node: node, name: itemName)
        
        return FileProviderItem(node: renamedNode)
    }
    
    override func trashItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier) async throws -> NSFileProviderItem {
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let movedNode = try await nodeActionUseCase.trash(node: node)
        
        return FileProviderItem(node: movedNode)
    }
    
    override func untrashItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier?) async throws -> NSFileProviderItem {
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let movedNode = try await nodeActionUseCase.untrash(node: node)
        
        return FileProviderItem(node: movedNode)
    }
    
    override func deleteItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier) async throws {
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        try await nodeActionUseCase.delete(node: node)
    }
    
    override func reparentItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toParentItemWithIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, newName: String?) async throws -> NSFileProviderItem {
        guard let parentNode = node(for: parentItemIdentifier),
              let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let movedNode = try await nodeActionUseCase.move(node: node, toParent: parentNode)
        
        return FileProviderItem(node: movedNode)
    }
    
    override func importDocument(at fileURL: URL, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier) async throws -> NSFileProviderItem {
        guard let parentNode = node(for: parentItemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let transfer = try await transferUseCase.uploadFile(at: fileURL, to: parentNode, startHandler: {  _ in
            NSFileProviderManager.default.signalEnumerator(for: parentItemIdentifier) { error in
                if let error {
                    MEGALogError("Error signaling item: \(error)")
                }
            }
        })
        
        try await NSFileProviderManager.default.signalEnumerator(for: parentItemIdentifier)
        
        guard let node = MEGASdk.shared.node(forHandle: transfer.nodeHandle) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        return FileProviderItem(node: node.toNodeEntity())
    }
    
    // MARK: - Private
    
    private func login() {
        guard credentialUseCase.hasSession() else {
            MEGALogError("[Picker] Can't login: no session stored in the keychain")
            return
        }
        
        let authUseCase = AuthUseCase(repo: AuthRepository(sdk: MEGASdk.shared), credentialRepo: CredentialRepository.newRepo)
        
        guard let sessionId = authUseCase.sessionId() else {
            MEGALogError("[Picker] Can't login: no session")
            return
        }
        
        let copyDataBasesUseCase = CopyDataBasesUseCase(repo: CopyDataBasesRepository(fileManager: FileManager.default))
        
        copyDataBasesUseCase.copyFromMainApp { (result) in
            switch result {
            case .success:
                MEGALogDebug("[Picker] Databases from main app copied")
            case .failure:
                MEGALogError("[Picker] Error copying databases from main app")
            }
        }
        
        Task {
            try await authUseCase.login(sessionId: sessionId)
            try await nodeActionUseCase.fetchnodes()
            semaphore.signal()
        }
    }
    
    private func node(for identifier: NSFileProviderItemIdentifier) -> NodeEntity? {
        var path: String
        if identifier == NSFileProviderItemIdentifier.rootContainer {
            path = "/"
        } else {
            path = identifier.rawValue
        }
        guard let node = MEGASdk.shared.node(forPath: path) else {
            return nil
        }
        return node.toNodeEntity()
    }
}
