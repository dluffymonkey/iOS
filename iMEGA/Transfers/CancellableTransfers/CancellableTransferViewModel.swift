
final class CancellableTransferViewModel: ViewModelType {
    
    private let uploadFileUseCase: UploadFileUseCaseProtocol
    private let downloadNodeUseCase: DownloadNodeUseCaseProtocol

    private let transfers: [CancellableTransfer]
    private let fileTransfers: [CancellableTransfer]
    private let folderTransfers: [CancellableTransfer]
    private let transferType: CancellableTransferType
    
    private let cancelToken = MEGACancelToken()
    private var processingComplete: Bool = false

    private var transferErrors = [TransferErrorEntity]()
    
    // MARK: - Private properties
    private let router: CancellableTransferRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: CancellableTransferRouting,
         uploadFileUseCase: UploadFileUseCaseProtocol,
         downloadNodeUseCase: DownloadNodeUseCaseProtocol,
         transfers: [CancellableTransfer],
         transferType: CancellableTransferType) {
        self.router = router
        self.uploadFileUseCase = uploadFileUseCase
        self.downloadNodeUseCase = downloadNodeUseCase
        self.transfers = transfers
        self.fileTransfers = transfers.filter { $0.isFile }
        self.folderTransfers = transfers.filter { !$0.isFile }
        self.transferType = transferType
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: CancellableTransferViewAction) {
        switch action {
        case .onViewReady:
            switch transferType {
            case .upload:
                if fileTransfers.count != 0 {
                    startFileUploads()
                } else {
                    startFolderUploads()
                }
            case .download:
                if fileTransfers.count != 0 {
                    startFileDownloads()
                } else {
                    startFolderDownloads()
                }
            case .downloadChat:
                startChatFileDownloads()
            }
        case .didTapCancelButton:
            if processingComplete {
                return
            }
            router.showConfirmCancel()
        case .didTapDismissConfirmCancel:
            router.dismissConfirmCancel()
        case .didTapProceedCancel:
            cancelToken.cancel(withNewValue: true)
            router.transferCancelled(with: Strings.Localizable.transferCancelled)
        }
    }
    
    // MARK: - Private
    private func fileTransfersStarted() -> Bool {
        fileTransfers.filter({ $0.state != .none }).count == fileTransfers.count
    }
    
    private func folderTransfersStartedTransferring() -> Bool {
        folderTransfers.filter({ $0.state == .failed || $0.stage == .transferringFiles }).count == folderTransfers.count
    }
    
    private func continueFolderTransfersIfNeeded() {
        guard !cancelToken.isCancelled else {
            return
        }
        
        guard folderTransfers.count != 0 else {
            manageTransfersCompletion()
            return
        }
        
        switch transferType {
        case .download:
            if fileTransfersStarted() {
                startFolderDownloads()
            }
        case .upload:
            if fileTransfersStarted() {
                startFolderUploads()
            }
        case .downloadChat:
            break
        }
    }
    
    private func checkIfAllTransfersStartedTranferring() {
        guard folderTransfersStartedTransferring(), !cancelToken.isCancelled else {
            return
        }
        manageTransfersCompletion()
    }
    
    private func manageTransfersCompletion() {
        processingComplete = true
        if transferErrors.isEmpty {
            switch self.transferType {
            case .download, .downloadChat:
                router.transferSuccess(with: Strings.Localizable.downloadStarted)
            case .upload:
                router.transferSuccess(with: Strings.Localizable.uploadStartedMessage)
            }
        } else if transferErrors.count < transfers.count {
            router.transferCompletedWithError(error: Strings.Localizable.somethingWentWrong)
        } else {
            router.transferFailed(error: String(format: "%@ %@", Strings.Localizable.transferFailed, Strings.Localizable.somethingWentWrong))
        }
    }
    
    //MARK: - Upload
    private func startFileUploads() {
        fileTransfers.forEach { transferViewEntity in
            uploadFileUseCase.uploadFile(withLocalPath: transferViewEntity.path,
                                         toParent: transferViewEntity.parentHandle,
                                         fileName: transferViewEntity.name,
                                         appData: transferViewEntity.appData,
                                         isSourceTemporary: false,
                                         startFirst: transferViewEntity.priority,
                                         cancelToken: cancelToken)
            { transferEntity in
                transferViewEntity.state = transferEntity.state
                self.continueFolderTransfersIfNeeded()
            } update: { _ in } completion: { [weak self]  result in
                switch result {
                case .success:
                    transferViewEntity.state = .complete
                case .failure(let error):
                    transferViewEntity.state = .failed
                    self?.transferErrors.append(error)
                }
                self?.continueFolderTransfersIfNeeded()
            }
        }
    }
    
    private func startFolderUploads() {
        folderTransfers.forEach { transferViewEntity in
            uploadFileUseCase.uploadFile(withLocalPath:transferViewEntity.path,
                                         toParent: transferViewEntity.parentHandle,
                                         fileName: nil,
                                         appData: transferViewEntity.appData,
                                         isSourceTemporary: false,
                                         startFirst: transferViewEntity.priority,
                                         cancelToken: cancelToken,
                                         start: nil)
            { transferEntity in
                transferViewEntity.stage = transferEntity.stage
                transferViewEntity.state = transferEntity.state
                switch transferEntity.stage {
                case .transferringFiles:
                    self.checkIfAllTransfersStartedTranferring()
                default:
                    break
                }
            } completion: { [weak self]  result in
                switch result {
                case .success:
                    transferViewEntity.state = .complete
                case .failure(let error):
                    transferViewEntity.state = .failed
                    self?.transferErrors.append(error)
                    self?.checkIfAllTransfersStartedTranferring()
                }
            }
        }
    }
    
    private func startChatFileDownloads() {
        fileTransfers.forEach { transferViewEntity in
            downloadNodeUseCase.downloadChatFileToOffline(forNodeHandle: transferViewEntity.handle,
                                                          messageId: transferViewEntity.messageId,
                                                          chatId: transferViewEntity.chatId,
                                                          toPath: transferViewEntity.path,
                                                          filename: transferViewEntity.name,
                                                          appdata: transferViewEntity.appData,
                                                          startFirst: transferViewEntity.priority,
                                                          cancelToken: cancelToken)
            { transferEntity in
                transferViewEntity.state = transferEntity.state
                self.continueFolderTransfersIfNeeded()
            } update: { _ in } completion: { [weak self] result in
                switch result {
                case .success(let transferEntity):
                    transferViewEntity.state = transferEntity.state
                case .failure(let error):
                    transferViewEntity.state = .failed
                    if error != .alreadyDownloaded && error != .copiedFromTempFolder {
                        self?.transferErrors.append(error)
                    }
                    self?.continueFolderTransfersIfNeeded()
                }
            }
        }
    }
    
    //MARK: - Downloads
    private func startFileDownloads() {
        fileTransfers.forEach { transferViewEntity in
            downloadNodeUseCase.downloadFileToOffline(forNodeHandle: transferViewEntity.handle,
                                                      toPath: transferViewEntity.path,
                                                      filename: transferViewEntity.name,
                                                      appdata: transferViewEntity.appData,
                                                      startFirst: transferViewEntity.priority,
                                                      cancelToken: cancelToken)
            { transferEntity in
                transferViewEntity.state = transferEntity.state
                self.continueFolderTransfersIfNeeded()
            } update: { _ in } completion: { [weak self] result in
                switch result {
                case .success(let transferEntity):
                    transferViewEntity.state = transferEntity.state
                case .failure(let error):
                    transferViewEntity.state = .failed
                    if error != .alreadyDownloaded && error != .copiedFromTempFolder {
                        self?.transferErrors.append(error)
                    }
                    self?.continueFolderTransfersIfNeeded()
                }
            }
        }
    }
    
    private func startFolderDownloads() {
        folderTransfers.forEach { transferViewEntity in
            downloadNodeUseCase.downloadFileToOffline(forNodeHandle: transferViewEntity.handle,
                                                      toPath: transferViewEntity.path,
                                                      filename: transferViewEntity.name,
                                                      appdata: transferViewEntity.appData,
                                                      startFirst: transferViewEntity.priority,
                                                      cancelToken: cancelToken,
                                                      start: nil)
            { transferEntity in
                transferViewEntity.stage = transferEntity.stage
                transferViewEntity.state = transferEntity.state
                switch transferEntity.stage {
                case .transferringFiles:
                    self.checkIfAllTransfersStartedTranferring()
                default:
                    break
                }
            } completion: { [weak self] result in
                switch result {
                case .success(let transferEntity):
                    transferViewEntity.state = transferEntity.state
                case .failure(let error):
                    transferViewEntity.state = .failed
                    if error != .alreadyDownloaded && error != .copiedFromTempFolder {
                        self?.transferErrors.append(error)
                    }
                    self?.checkIfAllTransfersStartedTranferring()
                }
            }
        }
    }
}
