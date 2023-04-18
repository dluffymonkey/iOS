import MEGADomain

final class ScheduleMeetingRouter {
    private(set) var presenter: UINavigationController
    private(set) var baseViewController: UINavigationController?

    init(presenter: UINavigationController) {
        self.presenter = presenter
    }
    
    func build() -> UINavigationController {
        let viewModel = ScheduleMeetingViewModel(
            router: self,
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared)),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        )

        let viewController = ScheduleMeetingViewController(viewModel: viewModel)
        let navigation = MEGANavigationController(rootViewController: viewController)
        
        baseViewController = navigation
        
        return navigation
    }
    
    func start() {
        presenter.present(build(), animated: true)
    }
}
    
extension ScheduleMeetingRouter: ScheduleMeetingRouting {
    func showSpinner() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
    }
    
    func hideSpinner() {
        SVProgressHUD.dismiss()
    }
    
    func dismissView() {
        SVProgressHUD.dismiss()
        presenter.dismissView()
    }

    func discardChanges() {
        presenter.dismissView()
    }
    
    func showAddParticipants(alreadySelectedUsers: [UserEntity], newSelectedUsers: @escaping (([UserEntity]?) -> Void)) {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        let contactsNavigationController = storyboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as! UINavigationController
        let contactController = contactsNavigationController.viewControllers.first as! ContactsViewController
        contactController.contactsMode = .scheduleMeeting
        contactController.chatOptionType = .meeting
        contactController.userSelected = { users in
            newSelectedUsers(users?.compactMap { $0.toUserEntity() })
        }
        
        baseViewController?.present(contactsNavigationController, animated: true) {
            contactController.selectUsers(alreadySelectedUsers.compactMap { $0.toMEGAUser() })
        }
    }
}