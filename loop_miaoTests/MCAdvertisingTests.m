#import <XCTest/XCTest.h>
#import "../loop_miao/Game/Ads/MCAdLoadState.h"
#import "../loop_miao/Game/Ads/MCFullScreenAdSlot.h"
#import "../loop_miao/Game/Ads/MCBannerAdSlot.h"
#import "../loop_miao/Game/Ads/MCAdManager.h"
#import "../loop_miao/Game/Ads/MCDailyAdCoordinator.h"
#import "../loop_miao/Game/Models/MCGameSession.h"

// Test doubles avoid ad requests, impressions and reward-network traffic.
@interface MCFakeInterstitial : NSObject
@property (nonatomic, weak) id delegate;
@property (nonatomic) BOOL ready;
@property (nonatomic) NSUInteger showCount;
- (BOOL)isReady;
- (void)showFrom:(UIViewController *)controller;
@end
@implementation MCFakeInterstitial
- (BOOL)isReady { return _ready; }
- (void)showFrom:(UIViewController *)controller { _showCount++; }
@end

@interface MCFakeBanner : UIView
@property (nonatomic, weak) id delegate;
@end
@implementation MCFakeBanner
@end

@interface MCOutcomeAdManager : MCAdManager
@property (nonatomic) NSInteger outcome;
@property (nonatomic) NSUInteger interstitialCalls;
@end
@implementation MCOutcomeAdManager
- (BOOL)showInterstitialFromViewController:(UIViewController *)presenter completion:(MCAdCompletion)completion {
    self.interstitialCalls++;
    return NO;
}
- (BOOL)showRewardedFromViewController:(UIViewController *)presenter rewardHandler:(MCAdRewardHandler)reward completion:(MCAdCompletion)completion {
    if(self.outcome==0)return NO;
    if(self.outcome==1)reward(@{});
    NSError *error=self.outcome==3?[NSError errorWithDomain:@"Test" code:3 userInfo:nil]:nil;
    completion(error); completion(error); // Even duplicate vendor terminal callbacks resolve once.
    return YES;
}
@end

// Declare delegate selectors without coupling the test target to Swift SDK headers.
@interface MCFullScreenAdSlot (TestCallbacks)
- (void)interstitialDidFinishLoading:(id)ad;
- (void)interstitialDidDismiss:(id)ad;
- (void)interstitial:(id)ad rewardActionCompletedWithRewards:(NSDictionary *)rewards;
- (void)interstitial:(id)ad didFailToPresentWithError:(NSError *)error;
@end
@interface MCBannerAdSlot (TestCallbacks)
- (void)bannerDidFinishLoading:(id)banner;
@end

@interface MCAdvertisingTests : XCTestCase
@end
@implementation MCAdvertisingTests
- (void)testFailuresBackOffAndLoadingCannotOverlap {
    MCAdLoadState *state = [MCAdLoadState new];
    XCTAssertTrue([state canLoadAtTime:0]); [state beginAtTime:0];
    XCTAssertFalse([state canLoadAtTime:119]); XCTAssertFalse([state hasTimedOutAtTime:119]);
    XCTAssertTrue([state hasTimedOutAtTime:120]);
    NSError *error = [NSError errorWithDomain:@"Test" code:1 userInfo:nil];
    [state fail:error atTime:120]; XCTAssertFalse([state canLoadAtTime:149]); XCTAssertTrue([state canLoadAtTime:150]);
    [state beginAtTime:150]; [state fail:error atTime:151];
    XCTAssertFalse([state canLoadAtTime:210]); XCTAssertTrue([state canLoadAtTime:211]);
    [state beginAtTime:211]; [state succeed]; XCTAssertFalse([state canLoadAtTime:1000]);
}
- (MCFakeInterstitial *)installFakeIn:(MCFullScreenAdSlot *)slot {
    MCFakeInterstitial *fake = [MCFakeInterstitial new]; fake.ready = YES;
    [slot setValue:fake forKey:@"ad"];
    [slot.loadState beginAtTime:0]; [slot interstitialDidFinishLoading:fake];
    return fake;
}
- (void)testLoadingNeverShowsAndRewardDeliveredOnlyOnce {
    MCFullScreenAdSlot *slot = [[MCFullScreenAdSlot alloc] initWithPlacementID:1 rewarded:YES];
    UIViewController *vc = [UIViewController new];
    XCTAssertFalse([slot showFrom:vc reward:nil completion:nil]);
    MCFakeInterstitial *fake = [self installFakeIn:slot];
    XCTAssertTrue(slot.ready); XCTAssertEqual(fake.showCount, 0u);
    __block NSUInteger rewards = 0, completions = 0;
    XCTAssertTrue([slot showFrom:vc reward:^(NSDictionary *value) { rewards++; } completion:^(NSError *error) { XCTAssertNil(error); completions++; }]);
    XCTAssertFalse([slot showFrom:vc reward:nil completion:nil]);
    [slot interstitial:fake rewardActionCompletedWithRewards:@{}];
    [slot interstitial:fake rewardActionCompletedWithRewards:@{}];
    XCTAssertEqual(rewards, 1u);
    [slot interstitialDidDismiss:fake]; [slot interstitialDidDismiss:fake];
    [slot interstitial:fake rewardActionCompletedWithRewards:@{}];
    XCTAssertEqual(completions, 1u); XCTAssertEqual(rewards, 1u); XCTAssertEqual(fake.showCount, 1u);
    XCTAssertFalse(slot.presenting); XCTAssertFalse(slot.ready);
}
- (void)testClosingOrFailingDoesNotGrantRewardAndStaleCallbacksAreIgnored {
    for (NSNumber *fail in @[@NO, @YES]) {
        MCFullScreenAdSlot *slot = [[MCFullScreenAdSlot alloc] initWithPlacementID:1 rewarded:YES];
        MCFakeInterstitial *fake = [self installFakeIn:slot];
        __block NSUInteger rewards = 0;
        [slot showFrom:[UIViewController new] reward:^(NSDictionary *value) { rewards++; } completion:nil];
        if (fail.boolValue) [slot interstitial:fake didFailToPresentWithError:[NSError errorWithDomain:@"Test" code:2 userInfo:nil]];
        else [slot interstitialDidDismiss:fake];
        [slot interstitialDidFinishLoading:fake];
        XCTAssertEqual(rewards, 0u); XCTAssertFalse(slot.ready);
    }
}
- (void)testBannerLoadStaysHiddenUntilExplicitShow {
    MCBannerAdSlot *slot = [[MCBannerAdSlot alloc] initWithPlacementID:2];
    MCFakeBanner *banner = [[MCFakeBanner alloc] initWithFrame:CGRectMake(0,0,320,50)]; banner.hidden = YES;
    [slot setValue:banner forKey:@"banner"];
    [slot bannerDidFinishLoading:banner];
    XCTAssertTrue(slot.ready); XCTAssertTrue(banner.hidden); XCTAssertNil(banner.superview);
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0,0,390,844)];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,50)]; [window addSubview:container];
    XCTAssertTrue([slot showInContainer:container]); XCTAssertFalse(banner.hidden); XCTAssertEqual(banner.superview, container);
    [slot hide]; XCTAssertTrue(banner.hidden); XCTAssertNil(banner.superview);
    [slot bannerDidFinishLoading:banner]; XCTAssertTrue(banner.hidden); XCTAssertNil(banner.superview);
}
- (void)testManagerRejectsInvisiblePresenterAndPausedRequests {
    MCAdManager *manager = [MCAdManager new];
    MCFullScreenAdSlot *slot = [manager valueForKey:@"interstitial"];
    MCFakeInterstitial *fake = [self installFakeIn:slot];
    XCTAssertFalse([manager showInterstitialFromViewController:[UIViewController new] completion:nil]);
    XCTAssertEqual(fake.showCount, 0u);
    [manager setAdRequestsPaused:YES]; XCTAssertFalse(manager.interstitialReady);
    [manager preloadAll]; XCTAssertFalse([[manager.status objectForKey:@"interstitialLoading"] boolValue]);
}
- (void)testBannerFinishingAfterOfferOpensAttachesToRequestedContainer {
    MCBannerAdSlot *slot=[[MCBannerAdSlot alloc]initWithPlacementID:2];
    MCFakeBanner *banner=[[MCFakeBanner alloc]initWithFrame:CGRectMake(0,0,320,50)];banner.hidden=YES;
    [slot setValue:banner forKey:@"banner"];
    UIWindow *window=[[UIWindow alloc]initWithFrame:CGRectMake(0,0,390,844)];
    UIView *container=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,50)];[window addSubview:container];
    XCTAssertFalse([slot showInContainer:container]);XCTAssertNil(banner.superview);
    [slot bannerDidFinishLoading:banner];
    XCTAssertEqual(banner.superview,container);XCTAssertFalse(banner.hidden);
    [slot hide];XCTAssertNil(banner.superview);
}
- (void)testClosingOfferBeforeBannerFinishesCancelsPendingDisplay {
    MCBannerAdSlot *slot=[[MCBannerAdSlot alloc]initWithPlacementID:2];
    MCFakeBanner *banner=[[MCFakeBanner alloc]initWithFrame:CGRectMake(0,0,320,50)];banner.hidden=YES;
    [slot setValue:banner forKey:@"banner"];
    UIWindow *window=[[UIWindow alloc]initWithFrame:CGRectMake(0,0,390,844)];
    UIView *container=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,50)];[window addSubview:container];
    XCTAssertFalse([slot showInContainer:container]);[slot hide];
    [slot bannerDidFinishLoading:banner];
    XCTAssertNil(banner.superview);XCTAssertTrue(banner.hidden);
}
- (void)testBannerCannotAttachToDetachedOffer {
    MCBannerAdSlot *slot=[[MCBannerAdSlot alloc]initWithPlacementID:2];
    MCFakeBanner *banner=[[MCFakeBanner alloc]initWithFrame:CGRectMake(0,0,320,50)];banner.hidden=YES;
    [slot setValue:banner forKey:@"banner"];
    UIWindow *window=[[UIWindow alloc]initWithFrame:CGRectMake(0,0,390,844)];
    UIView *container=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,50)];[window addSubview:container];
    XCTAssertFalse([slot showInContainer:container]);[container removeFromSuperview];
    [slot bannerDidFinishLoading:banner];XCTAssertNil(banner.superview);XCTAssertTrue(banner.hidden);
}
- (void)testRewardOutcomeCallsExactlyOneBranchForEveryExit {
    for(NSInteger scenario=0;scenario<4;scenario++){
        MCOutcomeAdManager *manager=[MCOutcomeAdManager new];manager.outcome=scenario;
        __block NSUInteger earned=0,notEarned=0;
        [manager presentRewardedFromViewController:[UIViewController new] onReward:^(NSDictionary *rewards){earned++;} withoutReward:^(NSError *error){notEarned++;}];
        XCTAssertEqual(earned+notEarned,1u);
        XCTAssertEqual(earned,scenario==1?1u:0u);
    }
}
- (void)testEveryDailyRestartCallsPlacementEvenWhenUnavailable {
    MCGameSession *session=[MCGameSession new];[session startDailyAtDate:NSDate.date reset:YES];
    UIViewController *presenter=[UIViewController new];
    UIWindow *window=[[UIWindow alloc]initWithFrame:CGRectMake(0,0,390,844)];
    [window addSubview:presenter.view];
    MCOutcomeAdManager *ads=[MCOutcomeAdManager new];
    MCDailyAdCoordinator *flow=[[MCDailyAdCoordinator alloc]initWithPresenter:presenter session:session ads:ads];
    __block NSUInteger restarts=0;
    flow.restart=^{restarts++;[session startDailyAtDate:NSDate.date reset:YES];};
    [flow requestRestart];[flow requestRestart];[flow requestRestart];
    XCTAssertEqual(ads.interstitialCalls,3u);XCTAssertEqual(restarts,3u);XCTAssertFalse(flow.busy);
    XCTAssertFalse(session.dailyAdBreakActive);[flow invalidate];
}
- (void)testDailyRewardAdds120SecondsOnceAndSurvivesReload {
    MCGameSession *session=[MCGameSession new];NSDate *now=NSDate.date;
    [session startDailyAtDate:now reset:YES];NSTimeInterval original=[session dailyRemainingAtDate:now];
    NSString *token=[session beginDailyAdBreakAtDate:now];XCTAssertNotNil(token);
    NSDate *later=[now dateByAddingTimeInterval:45];
    XCTAssertEqualWithAccuracy([session dailyRemainingAtDate:later],original,.01);
    XCTAssertTrue([session endDailyAdBreak:token rewardSeconds:120 atDate:later]);
    XCTAssertEqualWithAccuracy([session dailyRemainingAtDate:later],original+120,.01);
    XCTAssertFalse([session endDailyAdBreak:token rewardSeconds:120 atDate:later]);
    MCGameSession *restored=[MCGameSession new];[restored startDailyAtDate:later reset:NO];
    XCTAssertEqualWithAccuracy([restored dailyRemainingAtDate:later],original+120,.01);
    token=[session beginDailyAdBreakAtDate:later];
    [session startDailyAtDate:later reset:YES];
    XCTAssertFalse([session endDailyAdBreak:token rewardSeconds:120 atDate:later]);
}
- (void)testUnrewardedVideoOnlyRestoresPausedTime {
    MCGameSession *session=[MCGameSession new];NSDate *now=NSDate.date;
    [session startDailyAtDate:now reset:YES];NSTimeInterval original=[session dailyRemainingAtDate:now];
    NSString *token=[session beginDailyAdBreakAtDate:now];NSDate *later=[now dateByAddingTimeInterval:20];
    XCTAssertTrue([session endDailyAdBreak:token rewardSeconds:0 atDate:later]);
    XCTAssertEqualWithAccuracy([session dailyRemainingAtDate:later],original,.01);
    XCTAssertEqualWithAccuracy([session dailyRemainingAtDate:[later dateByAddingTimeInterval:5]],original-5,.01);
}
@end
