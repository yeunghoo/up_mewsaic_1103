#import "MCDailyChallengeStore.h"
@implementation MCDailyChallengeStore
@synthesize levels = _levels;
- (NSArray<NSDictionary *> *)levels {
    // Home only needs the completion badge. Load expert boards on first entry,
    // keeping their file I/O and JSON parsing out of the app's launch path.
    if(!_levels){
        NSURL *url=[NSBundle.mainBundle URLForResource:@"daily" withExtension:@"json"];
        NSData *data=url?[NSData dataWithContentsOfURL:url]:nil;
        _levels=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:@[];
    }return _levels;
}
+ (NSString *)dayKeyForDate:(NSDate *)date {
    NSDateFormatter *f=[NSDateFormatter new];f.locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en_US_POSIX"];
    f.calendar=[[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];f.timeZone=NSTimeZone.localTimeZone;f.dateFormat=@"yyyy-MM-dd";
    return [f stringFromDate:date];
}
- (NSInteger)indexForDate:(NSDate *)date {
    NSCalendar *calendar=[[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];calendar.timeZone=NSTimeZone.localTimeZone;
    NSInteger day=[calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitEra forDate:date];
    return self.levels.count?(day-1)%self.levels.count:0;
}
- (BOOL)isCompletedOnDate:(NSDate *)date {
    return [NSUserDefaults.standardUserDefaults dictionaryForKey:@"atelier.dailyCompleted"][[self.class dayKeyForDate:date]]!=nil;
}
- (void)recordCompletionForDay:(NSString *)day remaining:(NSTimeInterval)remaining {
    NSMutableDictionary *records=[[NSUserDefaults.standardUserDefaults dictionaryForKey:@"atelier.dailyCompleted"] mutableCopy]?:[NSMutableDictionary new];
    records[day]=@(MAX(remaining,[records[day] doubleValue]));[NSUserDefaults.standardUserDefaults setObject:records forKey:@"atelier.dailyCompleted"];
}
@end
