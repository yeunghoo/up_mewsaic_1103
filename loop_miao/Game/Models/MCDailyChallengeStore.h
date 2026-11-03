#import <Foundation/Foundation.h>
@interface MCDailyChallengeStore : NSObject
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *levels;
+ (NSString *)dayKeyForDate:(NSDate *)date;
- (NSInteger)indexForDate:(NSDate *)date;
- (BOOL)isCompletedOnDate:(NSDate *)date;
- (void)recordCompletionForDay:(NSString *)day remaining:(NSTimeInterval)remaining;
@end
