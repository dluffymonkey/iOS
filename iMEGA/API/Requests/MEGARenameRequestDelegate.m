
#import "MEGARenameRequestDelegate.h"

@interface MEGARenameRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);

@end

@implementation MEGARenameRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion {
    self = [super init];
    if(self) {
        _completion = completion;
    }
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    if (self.completion) {
        self.completion(request);
    }
}

@end
