#import <UIKit/UIKit.h>
#import "MCAdLoadState.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^MCAdRewardHandler)(NSDictionary<NSString *, id> *rewards);
typedef void (^MCAdCompletion)(NSError * _Nullable error);

@interface MCFullScreenAdSlot : NSObject
@property (nonatomic, readonly) MCAdLoadState *loadState;
@property (nonatomic, readonly) BOOL ready;
@property (nonatomic, readonly) BOOL presenting;
- (instancetype)initWithPlacementID:(int64_t)placementID rewarded:(BOOL)rewarded;
- (void)preloadAtTime:(NSTimeInterval)now;
/// A NO return never schedules a later presentation or invokes callbacks.
- (BOOL)showFrom:(UIViewController *)presenter reward:(nullable MCAdRewardHandler)reward completion:(nullable MCAdCompletion)completion;
- (void)discard;
@end
NS_ASSUME_NONNULL_END
