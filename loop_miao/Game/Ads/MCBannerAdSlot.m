#import "MCBannerAdSlot.h"
#import "MCAdLog.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
@import InMobiSDK;
#pragma clang diagnostic pop

@interface MCBannerAdSlot () <IMBannerDelegate>
@end
@implementation MCBannerAdSlot {
    int64_t _placementID;
    IMBanner *_banner;
    NSTimeInterval _loadedAt;
    NSArray<NSLayoutConstraint *> *_constraints;
    __weak UIView *_requestedContainer;
}
- (instancetype)initWithPlacementID:(int64_t)placementID {
    if ((self = [super init])) { _placementID = placementID; _loadState = [MCAdLoadState new]; }
    return self;
}
- (BOOL)ready { return _loadState.loaded && _banner != nil && NSProcessInfo.processInfo.systemUptime - _loadedAt < 1800; }
- (void)hide {
    _requestedContainer=nil;
    [self detachBanner];
}
- (void)detachBanner {
    if(_banner.superview)MCAdLog(@"隐藏横幅：随视频确认弹窗一起移除。");
    _banner.hidden = YES;
    [NSLayoutConstraint deactivateConstraints:_constraints ?: @[]]; _constraints = nil;
    [_banner removeFromSuperview];
}
- (void)discard {
    if (_presentingScreen) return;
    // Retain the caller's presentation request across load failure/retry, but
    // never retain its view. Only hide cancels that request.
    [self detachBanner]; _banner.delegate = nil; _banner = nil; [_loadState invalidate];
}
- (void)preloadAtTime:(NSTimeInterval)now {
    if (_presentingScreen || _banner.superview) return;
    if ([_loadState hasTimedOutAtTime:now]) {
        [self discard];
        [_loadState fail:[NSError errorWithDomain:@"MCAds" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Banner loading timed out."}] atTime:now];
    }
    if (_loadState.loaded && !self.ready) [self discard];
    if (![_loadState canLoadAtTime:now]) return;
    _banner.delegate = nil;
    _banner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 50) placementId:_placementID delegate:self];
    _banner.hidden = YES;
    [_banner shouldAutoRefresh:NO];
    [_loadState beginAtTime:now];MCAdLog(@"开始加载横幅，广告位=%lld，自动刷新已关闭。",(long long)_placementID); [_banner load];
}
- (BOOL)showInContainer:(UIView *)container {
    [container layoutIfNeeded];
    if (_presentingScreen || !container.window || container.hidden || container.alpha < 0.01 ||
        CGRectGetWidth(container.bounds) < 320 || CGRectGetHeight(container.bounds) < 50) return NO;
    _requestedContainer=container;
    if(!self.ready)return NO;
    [self detachBanner];
    _banner.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:_banner];
    _constraints = @[[ _banner.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
                     [_banner.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
                     [_banner.widthAnchor constraintEqualToConstant:320],
                     [_banner.heightAnchor constraintEqualToConstant:50]];
    [NSLayoutConstraint activateConstraints:_constraints];
    _banner.hidden = NO;
    MCAdLog(@"横幅已加入视频弹窗同层的底部容器。");
    return YES;
}
- (void)bannerDidFinishLoading:(IMBanner *)banner {
    if (banner != _banner) return;
    _loadedAt = NSProcessInfo.processInfo.systemUptime;
    [_loadState succeed];
    MCAdLog(@"横幅加载成功；保持隐藏且不加入页面。");
    // A live offer may have explicitly requested this banner before loading
    // finished. A closed offer calls hide, which clears the weak request.
    UIView *container=_requestedContainer;
    if(container){
        MCAdLog(@"检测到仍有效的弹窗横幅请求，尝试补显示。");
        [self showInContainer:container];
    }
}
- (void)banner:(IMBanner *)banner didFailToLoadWithError:(IMRequestStatus *)error {
    if (banner != _banner) return;
    MCAdLog(@"横幅加载失败：domain=%@ code=%ld reason=%@。",error.domain,(long)error.code,error.localizedDescription);
    [self discard]; [_loadState fail:error atTime:NSProcessInfo.processInfo.systemUptime];
}
- (void)banner:(IMBanner *)banner didFailToReceiveWithError:(IMRequestStatus *)error {
    [self banner:banner didFailToLoadWithError:error];
}
- (void)bannerWillPresentScreen:(IMBanner *)banner { if (banner == _banner) _presentingScreen = YES; }
- (void)bannerDidDismissScreen:(IMBanner *)banner { if (banner == _banner) _presentingScreen = NO; }
@end
