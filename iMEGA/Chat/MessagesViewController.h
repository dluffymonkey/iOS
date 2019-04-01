#import <UIKit/UIKit.h>
#import "JSQMessages.h"
#import "MEGASdkManager.h"

@interface MessagesViewController : JSQMessagesViewController <MEGAChatRoomDelegate>

@property (nonatomic, strong) MEGAChatRoom *chatRoom;
@property (nonatomic) NSURL *publicChatLink;
@property (nonatomic, getter=isPublicChatWithLinkCreated) BOOL publicChatWithLinkCreated;

- (void)updateUnreadLabel;

@end
