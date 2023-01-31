import MEGADomain

final class FilesSearchRepository: NSObject, FilesSearchRepositoryProtocol {
    
    static var newRepo: FilesSearchRepository {
        FilesSearchRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    private var callback: (([NodeEntity]) -> Void)?
    private var cancelToken: MEGACancelToken?
    
    private lazy var searchOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInitiated
        return operationQueue
    }()
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    // MARK: - Protocols
    public func allPhotos() async throws -> [NodeEntity] {
        try await rootNodeSearch(for: .photo)
    }
    
    func allVideos() async throws -> [NodeEntity] {
        try await rootNodeSearch(for: .video)
    }
    
    func startMonitoringNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        self.callback = callback
        sdk.add(self)
    }
    
    func stopMonitoringNodesUpdate() {
        sdk.remove(self)
    }
    
    func search(string: String?,
                parent node: NodeEntity?,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity,
                completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        guard let parent = node?.toMEGANode(in: sdk) ?? sdk.rootNode else {
            return completion(nil, true)
        }
        
        addSearchOperation(string: string,
                           parent: parent,
                           sortOrderType: sortOrderType,
                           formatType: formatType) { nodes, fail in
            let nodes = nodes?.toNodeEntities()
            completion(nodes,fail)
        }
    }
    
    func search(string: String?,
                parent node: NodeEntity?,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation({ continuation in
            search(string: string, parent: node, sortOrderType: sortOrderType, formatType: formatType) {
                guard Task.isCancelled == false else { continuation.resume(throwing: FileSearchResultErrorEntity.cancelled); return }
                
                continuation.resume(with: $0)
            }
        })
    }
    
    func node(by handle: HandleEntity) async -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
    
    func cancelSearch() {
        guard searchOperationQueue.operationCount > 0 else { return }
        
        cancelToken?.cancel()
        searchOperationQueue.cancelAllOperations()
    }
    
    //MARK: - Private
    
    private func rootNodeSearch(for nodeFormatType: MEGANodeFormatType) async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else { continuation.resume(throwing: FileSearchResultErrorEntity.generic); return }
            guard let rootNode = sdk.rootNode else {
                return continuation.resume(throwing: FileSearchResultErrorEntity.noDataAvailable)
            }
            
            let nodeList = sdk.nodeListSearch(
                for: rootNode,
                search: "",
                cancelToken: MEGACancelToken(),
                recursive: true,
                orderType: .modificationDesc,
                nodeFormatType: nodeFormatType,
                folderTargetType: .rootNode
            )
            
            continuation.resume(returning: nodeList.toNodeEntities())
        }
    }
    
    private func search(string: String?,
                        parent node: NodeEntity?,
                        sortOrderType: SortOrderEntity,
                        formatType: NodeFormatEntity,
                        completion: @escaping (Result<[NodeEntity], Error>) -> Void) {
        guard let parent = node?.toMEGANode(in: sdk) ?? sdk.rootNode else {
            return completion(.failure(NodeSearchResultErrorEntity.noDataAvailable))
        }
        
        addSearchOperation(string: string,
                           parent: parent,
                           sortOrderType: sortOrderType,
                           formatType: formatType) { nodes, fail in
            let nodes = nodes?.toNodeEntities()
            completion(fail ? .failure(NodeSearchResultErrorEntity.noDataAvailable) : .success(nodes ?? []))
        }
    }
    
    private func addSearchOperation(string: String?,
                                    parent: MEGANode,
                                    sortOrderType: SortOrderEntity,
                                    formatType: NodeFormatEntity,
                                    completion: @escaping ([MEGANode]?, Bool) -> Void) {
        cancelToken = MEGACancelToken()
        
        if let cancelToken {
            let searchOperation = SearchOperation(parentNode: parent,
                                                  text: string ?? "",
                                                  cancelToken: cancelToken,
                                                  sortOrderType: sortOrderType.toMEGASortOrderType(),
                                                  nodeFormatType: formatType.toMEGANodeFormatType(),
                                                  completion: completion)
            searchOperationQueue.addOperation(searchOperation)
        }
    }
}

extension FilesSearchRepository: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        callback?(nodeList?.toNodeEntities() ?? [])
    }
}