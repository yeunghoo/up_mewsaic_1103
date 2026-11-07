#import "MCTrackingAuthorization.h"
#import "MCAdLog.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

@implementation MCTrackingAuthorization {
    BOOL _requesting;
}
- (BOOL)resolveForWindow:(UIWindow *)window completion:(dispatch_block_t)completion {
    NSAssert(NSThread.isMainThread, @"ATT must run on the main thread");
    if (ATTrackingManager.trackingAuthorizationStatus != ATTrackingManagerAuthorizationStatusNotDetermined) return YES;
    if (_requesting || UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
        !window.isKeyWindow || window.hidden || !window.rootViewController.viewIfLoaded.window ||
        window.rootViewController.presentedViewController) return NO;
    _requesting = YES;
    MCAdLog(@"ATT：应用已激活，开始请求系统追踪授权。");
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_requesting = NO;
            MCAdLog(@"ATT：授权回调=%ld（0=未决定，1=受限，2=拒绝，3=允许）。拒绝不影响正常游戏。",(long)status);
            // An interrupted prompt can remain undetermined. The next active tick retries.
            if (status != ATTrackingManagerAuthorizationStatusNotDetermined) completion();
        });
    }];
    return NO;
}
@end
