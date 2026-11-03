#import <Foundation/Foundation.h>
#import "MCBoard.h"

@interface MCVolleyShot : NSObject
@property(nonatomic) NSInteger index;
@property(nonatomic) NSInteger slot;
@property(nonatomic,copy) NSString *color;
@property(nonatomic) NSTimeInterval launchedAt;
@property(nonatomic) double progress;
@end

/// Presentation simulation: independent cannon clocks, collision reservations and outside-air gating.
/// Logical MCBoard transactions stay deterministic and replayable while loads overlap visually.
@interface MCVolleyTimeline : NSObject
@property(nonatomic,strong,readonly) NSMutableDictionary<NSNumber *,NSString *> *colors;
@property(nonatomic,copy,readonly) NSArray<MCVolleyShot *> *launched;
@property(nonatomic,copy,readonly) NSArray<MCVolleyShot *> *impacts;
@property(nonatomic,copy,readonly) NSArray<MCVolleyShot *> *flying;
@property(nonatomic,readonly) BOOL running;
- (instancetype)initWithBoard:(MCBoard *)board;
- (BOOL)isSlotAnimating:(NSInteger)slot;
- (void)enqueueMove:(MCMove *)move;
- (NSDictionary *)snapshot;
- (BOOL)restoreSnapshot:(NSDictionary *)snapshot;
@property(nonatomic,copy,readonly) NSArray *displaySlots;
- (void)advance:(NSTimeInterval)elapsed;
@end
