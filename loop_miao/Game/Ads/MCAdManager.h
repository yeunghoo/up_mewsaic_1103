#import <UIKit/UIKit.h>
#import "MCFullScreenAdSlot.h"

NS_ASSUME_NONNULL_BEGIN
/// Main-thread facade. Preloading is independent of gameplay and never shows UI.
@interface MCAdManager : NSObject
@property (class, nonatomic, readonly) MCAdManager *sharedManager;
@property (nonatomic, readonly) BOOL initialized;
@property (nonatomic, readonly) BOOL interstitialReady;
@property (nonatomic, readonly) BOOL rewardedReady;
@property (nonatomic, readonly) BOOL bannerReady;
@property (nonatomic, readonly) BOOL fullScreenAdVisible;
/// Snapshot for diagnostics; no user/device identifiers.
@property (nonatomic, readonly) NSDictionary<NSString *, id> *status;
- (void)start;
- (void)preloadAll;
- (BOOL)showInterstitialFromViewController:(UIViewController *)presenter completion:(nullable MCAdCompletion)completion;
- (BOOL)showRewardedFromViewController:(UIViewController *)presenter rewardHandler:(MCAdRewardHandler)rewardHandler completion:(nullable MCAdCompletion)completion;
/// Exactly one outcome, after dismissal/failure. A not-ready request also calls
/// withoutReward. Closing early is represented by a nil error and no reward.
- (void)presentRewardedFromViewController:(UIViewController *)presenter onReward:(MCAdRewardHandler)onReward withoutReward:(MCAdCompletion)withoutReward;
/// Requests a banner in this container until hideBanner. Returns whether it was
/// attached immediately; a pending load may attach only while the request lives.
- (BOOL)showBannerInContainer:(UIView *)container;
- (void)hideBanner;
/// Future CMP integration: suspend BEFORE presenting consent UI, resume only with
/// a valid regional decision. ATT authorization is never treated as GDPR consent.
- (void)setAdRequestsPaused:(BOOL)paused;
- (void)updateConsentDictionary:(NSDictionary<NSString *, id> *)consent;
@end
NS_ASSUME_NONNULL_END
