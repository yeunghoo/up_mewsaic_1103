#import "MCDailyAdCoordinator.h"
#import "MCAdManager.h"
#import "MCAdConfiguration.h"
#import "../Models/MCGameSession.h"
#import "../Screens/MCRewardOfferViewController.h"
#import "../Views/MCAdNotice.h"

@implementation MCDailyAdCoordinator {
    __weak UIViewController *_presenter;
    MCGameSession *_session;
    MCAdManager *_ads;
    MCRewardOfferViewController *_offer;
    NSString *_breakToken;
    BOOL _invalidated;
}
- (instancetype)initWithPresenter:(UIViewController *)presenter session:(MCGameSession *)session ads:(MCAdManager *)ads {
    if ((self=[super init])) { _presenter=presenter; _session=session; _ads=ads; }
    return self;
}
- (BOOL)begin {
    if (_busy || _invalidated || !_session.dailyMode || !_presenter.viewIfLoaded.window || _presenter.presentedViewController) return NO;
    _breakToken=[_session beginDailyAdBreakAtDate:NSDate.date];
    if (!_breakToken) return NO;
    _busy=YES;
    if (self.suspensionChanged) self.suspensionChanged(YES);
    return YES;
}
- (BOOL)endWithReward:(NSTimeInterval)seconds {
    BOOL applied=[_session endDailyAdBreak:_breakToken rewardSeconds:seconds atDate:NSDate.date];
    _breakToken=nil; _busy=NO;
    if (!_invalidated && self.suspensionChanged) self.suspensionChanged(NO);
    return applied;
}
- (UIView *)noticeHost {
    // Router survives a restart; notices must not be attached to the old battle.
    return _presenter.parentViewController.view ?: _presenter.view;
}
- (void)requestRestart {
    if (![self begin]) return;
    __weak typeof(self) weakSelf=self;
    void (^finish)(NSError *)=^(NSError *error) {
        MCDailyAdCoordinator *self=weakSelf;
        if (!self || self->_invalidated) return;
        UIView *host=[self noticeHost];
        [self endWithReward:0];
        if (self.restart) self.restart();
        if (error) [MCAdNotice showText:@"Ad unavailable. Challenge restarted." inView:host success:NO];
    };
    // Always invoke the placement API, regardless of its current ready status.
    if (![_ads showInterstitialFromViewController:_presenter completion:finish]) {
        finish([NSError errorWithDomain:@"MCAds" code:2 userInfo:nil]);
    }
}
- (void)requestExtraTime {
    if (![self begin]) return;
    _offer=[[MCRewardOfferViewController alloc] initWithAdManager:_ads seconds:(NSInteger)MCDailyRewardSeconds];
    __weak typeof(self) weakSelf=self;
    _offer.decision=^(BOOL watch) {
        MCDailyAdCoordinator *self=weakSelf;
        if (!self || self->_invalidated) return;
        self->_offer=nil;
        if (!watch) { [self endWithReward:0]; return; }
        [self playRewardedVideo];
    };
    // No readiness check: every tap can open the offer, even while offline.
    [_presenter presentViewController:_offer animated:NO completion:nil];
}
- (void)playRewardedVideo {
    __weak typeof(self) weakSelf=self;
    [_ads presentRewardedFromViewController:_presenter onReward:^(NSDictionary *rewards) {
        [weakSelf didEarnReward:rewards];
    } withoutReward:^(NSError *error) {
        [weakSelf didFinishWithoutReward:error];
    }];
}
- (void)didEarnReward:(NSDictionary *)rewards {
    if (_invalidated) return;
    BOOL applied=[self endWithReward:MCDailyRewardSeconds];
    [MCAdNotice showText:applied?@"Reward earned! +120 seconds.":@"This challenge has ended. No time added." inView:[self noticeHost] success:applied];
}
- (void)didFinishWithoutReward:(NSError *)error {
    if (_invalidated) return;
    [self endWithReward:0];
    NSString *text=error?@"Video unavailable. No reward added.":@"Video not completed. No reward added.";
    [MCAdNotice showText:text inView:[self noticeHost] success:NO];
}
- (void)invalidate {
    _invalidated=YES;
    _offer.decision=nil;
    if (_offer) { [_ads hideBanner]; [_offer dismissViewControllerAnimated:NO completion:nil]; _offer=nil; }
    [self endWithReward:0];
    self.restart=nil; self.suspensionChanged=nil;
}
@end
