enum TransferErrorEntity: Error {
    case generic
    case upload
    case download
    case nodeNameUndefined
    case createDirectory
    case couldNotFindNodeByHandle
    case overquota
    case noInternetConnection
    case notEnoughSpace
    case inboxFolderNameNotAllowed
    case alreadyDownloaded
    case copiedFromTempFolder
    case moveFileToUploadsFolderFailed
}
