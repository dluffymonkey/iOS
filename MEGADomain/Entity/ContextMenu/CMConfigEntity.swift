
/// Configure the parameters needed to create a new CMEntity by the ContextMenuBuilder
///
///  - Parameters:
///     - menuType: The type of context menu used in each case
///     - viewMode: The current view mode (List, Thumbnail)
///     - accessLevel: The access level type for the current folder
///     - sortType: The selected sort type for this folder
///     - isRubbishBinFolder: Indicates whether or not it is the RubbishBin folder
///     - isRestorable: Indicates if the current node is restorable
///     - isInVersionsView: Indicates whether or not it is versions view
///     - isSharedItems: Indicates whether or not it is the shared items screen
///     - isIncomingShareChild: Indicates whether or not it is an incoming shared child folder
///     - isHome: Indicates whether or not it is the home screen
///     - isDocumentExplorer: Indicates whether or not it is the home docs explorer
///     - isAudiosExplorer: Indicates whether or not it is the home audios explorer
///     - isVideosExplorer: Indicates whether or not it is the home videos explorer
///     - isDoNotDisturbEnabled: Indicates wether or not the notifications are disabled
///     - isShareAvailable: Indicates if the share action is available
///     - timeRemainingToDeactiveDND: Indicates the remaining time to active again the notifications
///     - versionsCount: The number of versions of the current node
///     - showMediaDiscovery:  Indicates whether or not it is avaiable to show Media Discovery
///     - chatStatus: Indicates the user chat status (online, away, busy, offline...)
///
struct CMConfigEntity {
    let menuType: ContextMenuType
    var viewMode: ViewModePreference? = nil
    var accessLevel: MEGAShareType? = nil
    var sortType: SortOrderType? = nil
    var isAFolder: Bool = false
    var isRubbishBinFolder: Bool = false
    var isRestorable: Bool = false
    var isInVersionsView: Bool = false
    var isSharedItems: Bool = false
    var isIncomingShareChild: Bool = false
    var isHome: Bool = false
    var isDocumentExplorer: Bool = false
    var isAudiosExplorer: Bool = false
    var isVideosExplorer: Bool = false
    var isDoNotDisturbEnabled: Bool = false
    var isShareAvailable: Bool = false
    var timeRemainingToDeactiveDND: String? = nil
    var versionsCount: Int = 0
    var showMediaDiscovery: Bool = false
    var chatStatus: ChatStatus = .invalid
}