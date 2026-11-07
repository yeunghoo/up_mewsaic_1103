#import <UIKit/UIKit.h>
#import "MCAdLoadState.h"

NS_ASSUME_NONNULL_BEGIN
@interface MCBannerAdSlot : NSObject
@property (nonatomic, readonly) MCAdLoadState *loadState;
@property (nonatomic, readonly) BOOL ready;
@property (nonatomic, readonly) BOOL presentingScreen;
- (instancetype)initWithPlacementID:(int64_t)placementID;
- (void)preloadAtTime:(NSTimeInterval)now;
/// Caller reserves a visible, safe-area container of at least 320 x 50 points.
/// If loading is pending, remembers this weak container until hide is called.
- (BOOL)showInContainer:(UIView *)container;
- (void)hide;
- (void)discard;
@end
NS_ASSUME_NONNULL_END
