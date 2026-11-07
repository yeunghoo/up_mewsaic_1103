#import <UIKit/UIKit.h>
@class MCAdManager;

NS_ASSUME_NONNULL_BEGIN
/// Card and banner are siblings in one modal overlay, above the dimming view.
@interface MCRewardOfferViewController : UIViewController
@property (nonatomic, copy, nullable) void (^decision)(BOOL watchVideo);
- (instancetype)initWithAdManager:(MCAdManager *)ads seconds:(NSInteger)seconds;
- (void)closeWithoutWatching;
@end
NS_ASSUME_NONNULL_END
