#import "MCAdLoadState.h"

@implementation MCAdLoadState {
    NSTimeInterval _startedAt, _nextAttempt;
    NSUInteger _failures;
}
- (BOOL)canLoadAtTime:(NSTimeInterval)now { return !_loading && !_loaded && now >= _nextAttempt; }
- (BOOL)hasTimedOutAtTime:(NSTimeInterval)now { return _loading && now - _startedAt >= 120; }
- (void)beginAtTime:(NSTimeInterval)now {
    _loading = YES; _loaded = NO; _lastError = nil; _startedAt = now;
    _nextAttempt = now + 30; // Includes InMobi's minimum banner request interval.
}
- (void)succeed { _loading = NO; _loaded = YES; _failures = 0; _lastError = nil; }
- (void)fail:(NSError *)error atTime:(NSTimeInterval)now {
    _loading = NO; _loaded = NO; _lastError = error;
    _nextAttempt = now + MIN(300.0, 30.0 * (1UL << MIN(_failures, 4UL)));
    _failures++;
}
- (void)invalidate { _loading = NO; _loaded = NO; }
@end
