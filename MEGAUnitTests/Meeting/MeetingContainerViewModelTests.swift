import XCTest
@testable import MEGA

final class MeetingContainerViewModelTests: XCTestCase {

    func testAction_onViewReady() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callManagerUseCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: CallEntity(), callUseCase: MockCallUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUseCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        XCTAssert(router.showMeetingUI_calledTimes == 1)
        XCTAssert(callManagerUseCase.addCallRemoved_CalledTimes == 1)
    }
    
    func testAction_hangCall_attendeeIsGuest() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callEntity = CallEntity(chatId: 1, callId: 1, duration: 1, initialTimestamp: 1, finalTimestamp: 1, numberOfParticipants: 1)
        let callUseCase = MockCallUseCase()
        callUseCase.callEntity = CallEntity()
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: callEntity, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, hasUserLoggedIn: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callManagerUserCase.removeCallRemoved_CalledTimes == 1)
    }
    
    func testAction_hangCall_attendeeIsParticipantOrModerator() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callEntity = CallEntity(chatId: 1, callId: 1, duration: 1, initialTimestamp: 1, finalTimestamp: 1, numberOfParticipants: 1)
        let callUseCase = MockCallUseCase()
        callUseCase.callEntity = callEntity
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: CallEntity(hasLocalVideo: false), callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_backButtonTap() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: CallEntity(), callUseCase: MockCallUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        test(viewModel: viewModel, action: .tapOnBackButton, expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    func testAction_ChangeMenuVisibility() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: CallEntity(), callUseCase: MockCallUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        test(viewModel: viewModel, action: .changeMenuVisibility, expectedCommands: [])
        XCTAssert(router.toggleFloatingPanel_CalledTimes == 1)
    }

    func testAction_shareLink_Success() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let chatRoomUseCase = MockChatRoomUseCase(publicLinkCompletion: .success(""))
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: CallEntity(), callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 1)
    }
    
    func testAction_shareLink_Failure() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: CallEntity(), callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 0)
    }
}

final class MockMeetingContainerRouter: MeetingContainerRouting {
    var showMeetingUI_calledTimes = 0
    var dismiss_calledTimes = 0
    var toggleFloatingPanel_CalledTimes = 0
    var showEndMeetingOptions_calledTimes = 0
    var showOptionsMenu_calledTimes = 0
    var shareLink_calledTimes = 0
    var renameChat_calledTimes = 0
    var showMeetingError_calledTimes = 0
    var enableSpeaker_calledTimes = 0
    var didAddFirstParticipant_calledTimes = 0

    func showMeetingUI(containerViewModel: MeetingContainerViewModel) {
        showMeetingUI_calledTimes += 1
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        toggleFloatingPanel_CalledTimes += 1
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        dismiss_calledTimes += 1
        completion?()
    }
    
    func showEndMeetingOptions(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel, sender: UIButton) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func shareLink(presenter: UIViewController?, sender: AnyObject, link: String, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        shareLink_calledTimes += 1
    }
    
    func renameChat() {
        renameChat_calledTimes += 1
    }
    
    func showShareMeetingError() {
        showMeetingError_calledTimes += 1
    }
    
    func enableSpeaker(_ enable: Bool) {
        enableSpeaker_calledTimes += 1
    }
    
    func didAddFirstParticipant() {
        didAddFirstParticipant_calledTimes += 1
    }
}