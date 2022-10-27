@testable import MEGA

struct MockUserUseCase: UserUseCaseProtocol {
    var handle: UInt64 = 100
    var isLoggedIn: Bool = true
    var isGuest: Bool = false
    var userSDKEntity = UserSDKEntity(email: "", handle: 100, base64Handle: nil, change: nil, contact: nil)
    var contacts = [UserSDKEntity(email: "", handle: 101, base64Handle: nil, change: nil, contact: nil)]
    
    var myHandle: UInt64? {
        return handle
    }
    
    func user(withHandle handle: UInt64) -> UserSDKEntity? {
        guard userSDKEntity.handle == handle else { return nil }
        return userSDKEntity
    }
    
    public init(handle: UInt64 = 100, isLoggedIn: Bool = true, isGuest: Bool = false, userSDKEntity: UserSDKEntity = UserSDKEntity(email: "", handle: 100, base64Handle: nil, change: nil, contact: nil), contacts: [UserSDKEntity] = [UserSDKEntity(email: "", handle: 101, base64Handle: nil, change: nil, contact: nil)]) {
        self.handle = handle
        self.isLoggedIn = isLoggedIn
        self.isGuest = isGuest
        self.userSDKEntity = userSDKEntity
        self.contacts = contacts
    }
}
