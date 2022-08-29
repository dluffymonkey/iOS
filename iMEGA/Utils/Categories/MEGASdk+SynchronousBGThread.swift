extension MEGASdk {
    /// An async way to check if the current account is logged in or not.
    /// - Parameters:
    ///   - completion: Callback closure upon completion. The completion closure will be called from an arbitrary background thread.
    @objc(isLoggedInWithCompletion:)
    func isLoggedIn(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            completion(self.isLoggedIn() != 0)
        }
    }
    
    /// An async way to check if there are pending transfers.
    /// - Parameters:
    ///   - completion: Callback closure upon completion. The completion closure will be called from an arbitrary background thread.
    @objc(areTherePendingTransfersWithCompletion:)
    func areTherePendingTransfers(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            completion(self.transfers.size.intValue > 0 || self.transfers.size.intValue > 0)
        }
    }
    
    /// An async way to check if a node has versions.
    /// - Parameters:
    ///   - node: node to check
    ///   - completion: Callback closure upon completion. The completion closure will be called from an arbitrary background thread.
    @objc(hasVersionsForNode:completion:)
    func hasVersions(node: MEGANode, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var result = false
            if let self = self {
                result = self.hasVersions(for: node)
            }
            completion(result)
        }
    }
}