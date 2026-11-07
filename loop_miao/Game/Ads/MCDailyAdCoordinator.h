#import <UIKit/UIKit.h>
@class MCGameSession, MCAdManager;

NS_ASSUME_NONNULL_BEGIN
@interface MCDailyAdCoordinator : NSObject
@property (nonatomic, readonly) BOOL busy;
@property (nonatomic, copy, nullable) void (^suspensionChanged)(BOOL suspended);
@property (nonatomic, copy, nullable) dispatch_block_t restart;
- (instancetype)initWithPresenter:(UIViewController *)presenter session:(MCGameSession *)session ads:(MCAdManager *)ads;
- (void)requestRestart;
- (void)requestExtraTime;
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
