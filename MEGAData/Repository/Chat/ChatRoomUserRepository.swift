import Foundation
import MEGADomain

struct ChatRoomUserRepository: ChatRoomUserRepositoryProtocol {
    static var newRepo: ChatRoomUserRepository {
        ChatRoomUserRepository(sdk: .shared)
    }
    
    private let sdk: MEGAChatSdk
    private init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    func userFullName(forPeerId peerId: HandleEntity, chatRoom: ChatRoomEntity) async throws -> String {
        if let name = sdk.userFullnameFromCache(byUserHandle: peerId) {
            MEGALogDebug("user name is \(name) for handle \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
            return name
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = MEGAChatGenericRequestDelegate { (request, error) in
                guard error.type == .MEGAChatErrorTypeOk,
                      let name = self.sdk.userFullnameFromCache(byUserHandle: peerId) else {
                    MEGALogDebug("error fetching name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name") attributes \(error.type) : \(error.name ?? "")")
                    continuation.resume(throwing: ChatRoomErrorEntity.generic)
                    return
                }
                
                continuation.resume(returning: name)
            }
            
            
            MEGALogDebug("Load user name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
            sdk.loadUserAttributes(forChatId: chatRoom.chatId, usersHandles: [NSNumber(value: peerId)], delegate: delegate, queueType: .globalBackground)
        }
    }
    
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        sdk.contactEmail(byHandle: userHandle)
    }
}