#import "MCAdManager.h"
#import "MCAdConfiguration.h"
#import "MCBannerAdSlot.h"
#import "MCTrackingAuthorization.h"
#import "MCAdLog.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
@import InMobiSDK;
#pragma clang diagnostic pop

@implementation MCAdManager {
    MCTrackingAuthorization *_tracking;
    MCAdLoadState *_initialization;
    MCFullScreenAdSlot *_interstitial, *_rewarded;
    MCBannerAdSlot *_banner;
    NSTimer *_timer;
    BOOL _started, _paused;
    NSDictionary *_consent;
}
+ (MCAdManager *)sharedManager {
    static MCAdManager *manager; static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [MCAdManager new]; });
    return manager;
}
- (instancetype)init {
    if ((self = [super init])) {
        _tracking = [MCTrackingAuthorization new]; _initialization = [MCAdLoadState new];
        // No consent has been collected. Do not assert a jurisdiction or consent.
        _consent = @{@"gdpr_consent_available": @"false"};
        _interstitial = [[MCFullScreenAdSlot alloc] initWithPlacementID:MCInterstitialPlacementID rewarded:NO];
        _rewarded = [[MCFullScreenAdSlot alloc] initWithPlacementID:MCRewardedPlacementID rewarded:YES];
        _banner = [[MCBannerAdSlot alloc] initWithPlacementID:MCBannerPlacementID];
    }
    return self;
}
- (void)start {
    NSAssert(NSThread.isMainThread, @"Ads must run on the main thread");
    if (_started) return;
    _started = YES;
    MCAdLog(@"启动广告服务：等待前台激活和 ATT 决定；广告加载后保持隐藏。");
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(becameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(enteredBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) [self becameActive:nil];
}
- (void)becameActive:(NSNotification *)notification {
    if (!_timer) {
        __weak typeof(self) weakSelf = self;
        _timer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:YES block:^(NSTimer *timer) { [weakSelf preloadAll]; }];
        _timer.tolerance = 1;
    }
    // Let the scene finish activating before asking iOS to display ATT.
    dispatch_async(dispatch_get_main_queue(), ^{ [self preloadAll]; });
}
- (void)enteredBackground:(NSNotification *)notification { [_timer invalidate]; _timer = nil; }
- (UIWindow *)activeWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) if (window.isKeyWindow) return window;
    }
    return nil;
}
- (void)preloadAll {
    NSAssert(NSThread.isMainThread, @"Ads must run on the main thread");
    if (!_started || _paused || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    __weak typeof(self) weakSelf = self;
    if (![_tracking resolveForWindow:[self activeWindow] completion:^{ [weakSelf preloadAll]; }]) return;
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (!_initialized) {
        // Never overlap initialization calls. The SDK owns its initialization timeout.
        if (![_initialization canLoadAtTime:now]) return;
        [_initialization beginAtTime:now];
        MCAdLog(@"初始化 InMobi %@，ATT=%ld；GDPR 未声明同意。",[IMSdk getVersion],(long)ATTrackingManager.trackingAuthorizationStatus);
        [IMSdk initWithAccountID:MCInMobiAccountID consentDictionary:_consent andCompletionHandler:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                MCAdManager *self = weakSelf;
                if (!self) return;
                if (error) {
                    MCAdLog(@"SDK 初始化失败：domain=%@ code=%ld reason=%@；稍后退避重试。",error.domain,(long)error.code,error.localizedDescription);
                    [self->_initialization fail:error atTime:NSProcessInfo.processInfo.systemUptime];
                } else {
                    self->_initialized = YES; [self->_initialization succeed];
                    MCAdLog(@"SDK 初始化成功，分别预加载插页、横幅和激励视频。");
#if DEBUG
                    [IMSdk setLogLevel:IMSDKLogLevelError];
#else
                    [IMSdk setLogLevel:IMSDKLogLevelNone];
#endif
                    [self preloadAll];
                }
            });
        }];
        return;
    }
    [_interstitial preloadAtTime:now];
    [_rewarded preloadAtTime:now];
    [_banner preloadAtTime:now];
}
- (BOOL)interstitialReady { return !_paused && _interstitial.ready; }
- (BOOL)rewardedReady { return !_paused && _rewarded.ready; }
- (BOOL)bannerReady { return !_paused && _banner.ready; }
- (BOOL)fullScreenAdVisible { return _interstitial.presenting || _rewarded.presenting || _banner.presentingScreen; }
- (BOOL)canPresentFrom:(UIViewController *)presenter {
    return !_paused && !self.fullScreenAdVisible && UIApplication.sharedApplication.applicationState == UIApplicationStateActive &&
        presenter.viewIfLoaded.window.isKeyWindow && !presenter.presentedViewController &&
        !presenter.isBeingDismissed && !presenter.isBeingPresented;
}
- (BOOL)showInterstitialFromViewController:(UIViewController *)presenter completion:(MCAdCompletion)completion {
    NSAssert(NSThread.isMainThread, @"Ads must run on the main thread");
    MCAdLog(@"调用插页展示：ready=%d initialized=%d。",self.interstitialReady,self.initialized);
    if (![self canPresentFrom:presenter]) {MCAdLog(@"插页未展示：页面不可见、已有全屏广告或广告请求已暂停。");return NO;}
    BOOL shown = [_interstitial showFrom:presenter reward:nil completion:completion];
    if (!shown) {MCAdLog(@"插页尚未就绪：%@；尝试补充预加载，本次不等待。",_interstitial.loadState.lastError.localizedDescription?:@"仍在加载或尚未初始化");[self preloadAll];}
    return shown;
}
- (BOOL)showRewardedFromViewController:(UIViewController *)presenter rewardHandler:(MCAdRewardHandler)rewardHandler completion:(MCAdCompletion)completion {
    NSAssert(NSThread.isMainThread, @"Ads must run on the main thread");
    MCAdLog(@"调用激励视频展示：ready=%d initialized=%d。",self.rewardedReady,self.initialized);
    if (!rewardHandler || ![self canPresentFrom:presenter]) {MCAdLog(@"激励视频未展示：页面或回调条件不满足。");return NO;}
    return [_rewarded showFrom:presenter reward:rewardHandler completion:completion];
}
- (void)presentRewardedFromViewController:(UIViewController *)presenter onReward:(MCAdRewardHandler)onReward withoutReward:(MCAdCompletion)withoutReward {
    __block NSDictionary *earnedReward = nil;
    __block BOOL delivered = NO;
    MCAdCompletion finish = ^(NSError *error) {
        if (delivered) return;
        delivered = YES;
        if (earnedReward) {MCAdLog(@"激励视频最终结果：已获得奖励，触发成功回调。");onReward(earnedReward);}
        else {MCAdLog(@"激励视频最终结果：未获得奖励，触发失败/未完成回调。原因=%@",error.localizedDescription?:@"未达到奖励条件就关闭了广告");withoutReward(error);}
    };
    BOOL shown = [self showRewardedFromViewController:presenter rewardHandler:^(NSDictionary *reward) {
        earnedReward = reward ?: @{};
    } completion:finish];
    if (!shown) {
        MCAdLog(@"激励视频尚未就绪：%@；弹窗已关闭，不增加时间。",_rewarded.loadState.lastError.localizedDescription?:@"仍在加载或尚未初始化");
        [self preloadAll];
        finish([NSError errorWithDomain:@"MCAds" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Video unavailable. Please try again shortly."}]);
    }
}
- (BOOL)showBannerInContainer:(UIView *)container {
    NSAssert(NSThread.isMainThread, @"Ads must run on the main thread");
    MCAdLog(@"调用弹窗底部横幅展示：ready=%d。",self.bannerReady);
    if (_paused || self.fullScreenAdVisible || UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
        !container.window.isKeyWindow) return NO;
    BOOL shown=[_banner showInContainer:container];
    if(!shown)MCAdLog(@"横幅未展示：%@；或者容器尚未可见/小于 320×50。",_banner.loadState.lastError.localizedDescription?:@"广告尚未加载完成");
    return shown;
}
- (void)hideBanner { NSAssert(NSThread.isMainThread, @"Ads must run on the main thread"); [_banner hide]; }
- (void)setAdRequestsPaused:(BOOL)paused {
    NSAssert(NSThread.isMainThread, @"Ads must run on the main thread");
    _paused = paused;
    if (paused) { [_banner discard]; [_interstitial discard]; [_rewarded discard]; }
    else [self preloadAll];
}
- (void)updateConsentDictionary:(NSDictionary<NSString *,id> *)consent {
    NSAssert(NSThread.isMainThread, @"Ads must run on the main thread");
    _consent = [consent copy];
    if (_initialized) [IMSdk updateGDPRConsent:_consent];
    [_banner discard]; [_interstitial discard]; [_rewarded discard];
    [self preloadAll];
}
- (NSDictionary<NSString *,id> *)status {
    return @{@"initialized": @(_initialized), @"paused": @(_paused),
             @"interstitialReady": @(self.interstitialReady), @"rewardedReady": @(self.rewardedReady), @"bannerReady": @(self.bannerReady),
             @"interstitialLoading": @(_interstitial.loadState.loading), @"rewardedLoading": @(_rewarded.loadState.loading), @"bannerLoading": @(_banner.loadState.loading),
             @"initializationError": _initialization.lastError.localizedDescription ?: @"",
             @"interstitialError": _interstitial.loadState.lastError.localizedDescription ?: @"",
             @"rewardedError": _rewarded.loadState.lastError.localizedDescription ?: @"",
             @"bannerError": _banner.loadState.lastError.localizedDescription ?: @""};
}
@end
