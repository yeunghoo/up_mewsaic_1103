#import <Foundation/Foundation.h>
#import "MCBoard.h"
#import "MCDailyChallengeStore.h"
@interface MCGameSession : NSObject
@property(nonatomic,strong,readonly) NSArray<NSDictionary *> *catalog;
@property(nonatomic,strong,readonly) NSMutableSet<NSString *> *completed;
@property(nonatomic,strong) NSMutableArray *moves;
@property(nonatomic,strong) MCBoard *board;
@property(nonatomic) NSInteger levelIndex;
@property(nonatomic) NSInteger chapter;
@property(nonatomic) NSInteger galleryPage;
@property(nonatomic,strong,readonly) MCDailyChallengeStore *dailyStore;
@property(nonatomic,readonly) BOOL dailyMode;
@property(nonatomic,readonly) BOOL dailyFailed;
@property(nonatomic,copy,readonly) NSDictionary *currentLevelInfo;
@property(nonatomic,copy) NSDictionary *dailyVisualState;
@property(nonatomic,readonly) NSTimeInterval dailyDeadline;
@property(nonatomic,readonly) BOOL dailyAdBreakActive;
/// Temporary pause while the ad offer/video covers gameplay. The token makes
/// dismissal/reward idempotent and prevents a callback rewarding a new attempt.
- (NSString *)beginDailyAdBreakAtDate:(NSDate *)date;
- (BOOL)endDailyAdBreak:(NSString *)token rewardSeconds:(NSTimeInterval)seconds atDate:(NSDate *)date;
/// Resume a live attempt; expired/failed or test-only attempts start with a fresh clock.
- (void)startDailyAtDate:(NSDate *)date reset:(BOOL)reset;
- (void)restoreDailyMoves:(NSArray *)moves;
- (NSTimeInterval)dailyRemainingAtDate:(NSDate *)date;
- (void)failDaily;
- (NSInteger)unlocked;
- (void)start:(NSInteger)index moves:(NSArray *)moves;
- (void)resumeCampaign;
- (void)save;
+ (BOOL)replayMove:(id)record onBoard:(MCBoard *)board;
- (void)completeCurrentLevel;
@end
