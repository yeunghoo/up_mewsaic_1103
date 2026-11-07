#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// Main-thread only. Separate instance per placement; uses monotonic time.
@interface MCAdLoadState : NSObject
@property (nonatomic, readonly) BOOL loading;
@property (nonatomic, readonly) BOOL loaded;
@property (nonatomic, readonly, nullable) NSError *lastError;
- (BOOL)canLoadAtTime:(NSTimeInterval)now;
- (BOOL)hasTimedOutAtTime:(NSTimeInterval)now;
- (void)beginAtTime:(NSTimeInterval)now;
- (void)succeed;
- (void)fail:(NSError *)error atTime:(NSTimeInterval)now;
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
