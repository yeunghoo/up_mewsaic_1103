#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface MCTrackingAuthorization : NSObject
/// Returns YES once iOS has a resolved ATT decision, including denial/restriction.
/// Requests only while active, with a visible window and no competing modal.
- (BOOL)resolveForWindow:(nullable UIWindow *)window completion:(dispatch_block_t)completion;
@end
NS_ASSUME_NONNULL_END
