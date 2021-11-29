import Foundation

enum NodeLoadError: Error {
    case noRootNode
    case loadCancelled
    case invalidNode
}

final class NodeLoadOperation: MEGAOperation, NodeLoadOperationProtocol {
    // MARK: - Private properties
    private let loadNodeRequest: (MEGARequestDelegate) -> Void
    private let newNodeName: String?
    private let createNodeRequest: ((String, MEGANode, MEGARequestDelegate) -> Void)?
    private let setFolderHandleRequest: ((MEGAHandle, MEGARequestDelegate) -> Void)?
    private let completion: NodeLoadCompletion
    private let autoCreate: Bool
    let sdk: MEGASdk
    
    // MARK: - Init
    init(autoCreate: Bool = false,
         sdk: MEGASdk = MEGASdkManager.sharedMEGASdk(),
         loadNodeRequest: @escaping (MEGARequestDelegate) -> Void,
         newNodeName: String? = nil,
         createNodeRequest: ((String, MEGANode, MEGARequestDelegate) -> Void)? = nil,
         setFolderHandleRequest: ((MEGAHandle, MEGARequestDelegate) -> Void)? = nil,
         completion: @escaping NodeLoadCompletion) {
        self.autoCreate = autoCreate
        self.loadNodeRequest = loadNodeRequest
        self.newNodeName = newNodeName
        self.createNodeRequest = createNodeRequest
        self.setFolderHandleRequest = setFolderHandleRequest
        self.completion = completion
        self.sdk = sdk
        super.init()
    }
    
    // MARK: - Life cycle
    override func start() {
        guard !isCancelled else {
            finishOperation(node: nil, error: NodeLoadError.loadCancelled)
            return
        }
        
        startExecuting()
        loadNodeFromRemote()
    }
    
    func finishOperation(node: MEGANode?, error: Error?) {
        completion(node, error)
        finish()
    }
    
    // MARK: - Load from remote
    func loadNodeFromRemote() {
        loadNodeRequest(RequestDelegate(completion: validate))
    }
    
    // MARK: - Check loaded node handle
    func validateLoadedHandle(_ handle: NodeHandle) {
        guard let node = handle.validNode(in: sdk) else {
            autoCreate ?
                    createNode():
                    finishOperation(node: nil, error: NodeLoadError.invalidNode)
            return
        }
        finishOperation(node: node, error: nil)
    }
    
    func createNode() {
        guard let parent = sdk.rootNode, let newNodeName = newNodeName else {
            finishOperation(node: nil, error: NodeLoadError.noRootNode)
            return
        }
        
        createNodeRequest?(newNodeName, parent, RequestDelegate { [weak self] result in
            switch result {
            case .success(let request):
                self?.setTargetFolder(forHandle: request.nodeHandle)
            case .failure(let error):
                self?.finishOperation(node: nil, error: error)
            }
        })
    }
    
    func setTargetFolder(forHandle handle: NodeHandle) {
        setFolderHandleRequest?(handle, RequestDelegate(completion: validate))
    }
    
    private func validate(result: Result<MEGARequest, MEGAError>) {
        switch result {
        case .success(let request):
            validateLoadedHandle(request.nodeHandle)
        case .failure(let error):
            finishOperation(node: nil, error: error)
        }
    }
}
