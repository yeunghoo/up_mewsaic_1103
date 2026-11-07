#import "MCFullScreenAdSlot.h"
#import "MCAdLog.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
@import InMobiSDK;
#pragma clang diagnostic pop

@interface MCFullScreenAdSlot () <IMInterstitialDelegate>
@end

@implementation MCFullScreenAdSlot {
    int64_t _placementID;
    BOOL _rewarded, _rewardDelivered;
    IMInterstitial *_ad;
    MCAdRewardHandler _rewardHandler;
    MCAdCompletion _completion;
}
- (instancetype)initWithPlacementID:(int64_t)placementID rewarded:(BOOL)rewarded {
    if ((self = [super init])) {
        _placementID = placementID; _rewarded = rewarded; _loadState = [MCAdLoadState new];
    }
    return self;
}
- (BOOL)ready { return !_presenting && _loadState.loaded && [_ad isReady]; }
- (NSString *)formatName {return _rewarded?@"激励视频":@"插页";}
- (void)discard {
    if (_presenting) return;
    _ad.delegate = nil; _ad = nil; [_loadState invalidate];
}
- (void)preloadAtTime:(NSTimeInterval)now {
    if (_presenting) return;
    if ([_loadState hasTimedOutAtTime:now]) {
        MCAdLog(@"%@加载超过 120 秒，释放本次请求并退避重试。",self.formatName);
        [self discard];
        [_loadState fail:[NSError errorWithDomain:@"MCAds" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Ad loading timed out."}] atTime:now];
    }
    if (_loadState.loaded && ![_ad isReady]) [self discard];
    if (![_loadState canLoadAtTime:now]) return;
    _ad.delegate = nil;
    _ad = [[IMInterstitial alloc] initWithPlacementId:_placementID delegate:self];
    [_loadState beginAtTime:now];
    MCAdLog(@"开始加载%@，广告位=%lld。",self.formatName,(long long)_placementID);
    [_ad load];
}
- (BOOL)showFrom:(UIViewController *)presenter reward:(MCAdRewardHandler)reward completion:(MCAdCompletion)completion {
    if (!self.ready) return NO;
    _presenting = YES; _rewardDelivered = NO;
    _rewardHandler = [reward copy]; _completion = [completion copy];
    [_ad showFrom:presenter];
    MCAdLog(@"已向 SDK 提交%@展示请求。",self.formatName);
    return YES;
}
- (void)interstitialDidFinishLoading:(IMInterstitial *)ad {
    if (ad != _ad) return;
    [_loadState succeed]; // Loading must never present an ad.
    MCAdLog(@"%@加载成功，isReady=%d；保持隐藏，等待明确调用。",self.formatName,[_ad isReady]);
}
- (void)interstitial:(IMInterstitial *)ad didFailToLoadWithError:(IMRequestStatus *)error {
    if (ad != _ad) return;
    MCAdLog(@"%@加载失败：domain=%@ code=%ld reason=%@。",self.formatName,error.domain,(long)error.code,error.localizedDescription);
    [self discard]; [_loadState fail:error atTime:NSProcessInfo.processInfo.systemUptime];
}
- (void)interstitial:(IMInterstitial *)ad didFailToReceiveWithError:(NSError *)error {
    if (ad != _ad) return;
    MCAdLog(@"%@接收广告失败：domain=%@ code=%ld reason=%@。",self.formatName,error.domain,(long)error.code,error.localizedDescription);
    [self discard]; [_loadState fail:error atTime:NSProcessInfo.processInfo.systemUptime];
}
- (void)finishWithError:(NSError *)error {
    MCAdCompletion completion = _completion;
    _completion = nil; _rewardHandler = nil; _presenting = NO;
    [self discard];
    if (error) [_loadState fail:error atTime:NSProcessInfo.processInfo.systemUptime];
    if (completion) completion(error);
}
- (void)interstitial:(IMInterstitial *)ad didFailToPresentWithError:(IMRequestStatus *)error {
    if(ad==_ad)MCAdLog(@"%@展示失败：code=%ld reason=%@。",self.formatName,(long)error.code,error.localizedDescription);
    if (ad == _ad && _presenting) [self finishWithError:error];
}
- (void)interstitialDidDismiss:(IMInterstitial *)ad {
    if(ad==_ad)MCAdLog(@"%@已关闭，奖励完成=%d。",self.formatName,_rewardDelivered);
    if (ad == _ad && _presenting) [self finishWithError:nil];
}
- (void)interstitial:(IMInterstitial *)ad rewardActionCompletedWithRewards:(NSDictionary<NSString *,id> *)rewards {
    if (ad != _ad || !_rewarded || !_presenting || _rewardDelivered) return;
    _rewardDelivered = YES;
    MCAdLog(@"收到 SDK 激励奖励完成通知，仅记录一次；关闭广告后处理游戏奖励。");
    if (_rewardHandler) _rewardHandler(rewards);
}
- (void)interstitialDidPresent:(IMInterstitial *)ad {if(ad==_ad)MCAdLog(@"%@已实际展示到屏幕。",self.formatName);}
@end
