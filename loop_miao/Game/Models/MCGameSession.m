#import "MCGameSession.h"
#import <math.h>
@implementation MCGameSession {
    NSInteger _dailyIndex;
    NSString *_dailyDay;
    BOOL _dailyFinished;
    BOOL _dailyTestTimer;
    NSString *_dailyAdBreakToken;
    NSTimeInterval _dailyAdBreakRemaining;
}
+ (BOOL)replayMove:(id)record onBoard:(MCBoard *)board {
    if([record isKindOfClass:NSNumber.class])return [board playBasketAtQueueIndex:[record integerValue]]!=nil;
    if([record isKindOfClass:NSDictionary.class] && [record[@"pick"] isKindOfClass:NSNumber.class] && [record[@"slot"] isKindOfClass:NSNumber.class])
        return [board playBasketAtQueueIndex:[record[@"pick"] integerValue] slotIndex:[record[@"slot"] integerValue]]!=nil;
    return NO;
}
- (instancetype)init {if((self=[super init])){
    NSURL *url=[NSBundle.mainBundle URLForResource:@"campaign" withExtension:@"json"];
    NSData *data=url?[NSData dataWithContentsOfURL:url]:nil;
    _catalog=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:@[];
    _dailyStore=[MCDailyChallengeStore new];
    _completed=[NSMutableSet setWithArray:[NSUserDefaults.standardUserDefaults arrayForKey:@"atelier.completed"]?:@[]];
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"atelier.haptics":@YES,@"atelier.sound":@YES}];
    }return self;}
- (NSInteger)unlocked { NSInteger i=0;while(i<(NSInteger)self.catalog.count && [self.completed containsObject:self.catalog[i][@"id"]])i++;return MIN(i,(NSInteger)self.catalog.count-1); }
- (void)start:(NSInteger)index moves:(NSArray *)moves {
    _dailyAdBreakToken=nil;
    _dailyMode=NO;_dailyFailed=NO;self.dailyVisualState=nil;
    self.levelIndex=index;self.board=[[MCBoard alloc]initWithLevel:[MCLevel levelWithDictionary:self.catalog[index]]];self.moves=[NSMutableArray new];
    for(id record in moves){if(![MCGameSession replayMove:record onBoard:self.board])break;[self.moves addObject:record];}
    [self save];
}
- (void)resumeCampaign {
    if(!self.catalog.count)return;
    NSDictionary *saved=[NSUserDefaults.standardUserDefaults dictionaryForKey:@"atelier.session"];
    NSInteger index=saved?[saved[@"level"] integerValue]:self.unlocked;
    if(index<0||index>self.unlocked)index=self.unlocked;
    // Old ammo indexes cannot be replayed against regenerated content. Keep the
    // unlocked level/collection, restarting only the unfinished puzzle if needed.
    BOOL compatible=[saved[@"level"] integerValue]==index && [saved[@"revision"] integerValue]==2 && [saved[@"contentRevision"] integerValue]==[self.catalog[index][@"contentRevision"] integerValue];
    [self start:index moves:compatible?(saved[@"moves"]?:@[]):@[]];
}
- (NSDictionary *)currentLevelInfo {return self.dailyMode?self.dailyStore.levels[_dailyIndex]:self.catalog[self.levelIndex];}
- (void)startDailyAtDate:(NSDate *)date reset:(BOOL)reset {
    _dailyAdBreakToken=nil;
    _dailyMode=YES;_dailyFinished=NO;_dailyDay=[MCDailyChallengeStore dayKeyForDate:date];_dailyIndex=[self.dailyStore indexForDate:date];
    NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;
    NSTimeInterval limit=[self.currentLevelInfo[@"timeLimit"] doubleValue];_dailyTestTimer=NO;
#if DEBUG
    // Only an explicitly launched UI test may shorten the clock. A persisted debug
    // preference or a test attempt must never change the normal challenge duration.
    NSDictionary *arguments=[defaults volatileDomainForName:NSArgumentDomain];
    NSTimeInterval testSeconds=[arguments[@"MCDailySeconds"] doubleValue];
    if([arguments[@"MCUITesting"] boolValue]&&isfinite(testSeconds)&&testSeconds>0&&testSeconds<=3600){limit=testSeconds;_dailyTestTimer=YES;}
#endif
    NSDictionary *saved=reset?nil:[defaults dictionaryForKey:@"atelier.dailyAttempt"];
    NSTimeInterval deadline=[saved[@"deadline"] doubleValue];
    BOOL restore=[saved[@"day"] isEqual:_dailyDay] && [saved[@"index"] integerValue]==_dailyIndex && [saved[@"revision"] integerValue]==1
        && ![saved[@"failed"] boolValue] && isfinite(deadline) && deadline>date.timeIntervalSince1970
        && [saved[@"testTimer"] boolValue]==_dailyTestTimer;
    _dailyDeadline=restore?deadline:date.timeIntervalSince1970+limit;
    _dailyFailed=restore?[saved[@"failed"] boolValue]:NO;
    self.dailyVisualState=restore?saved[@"visual"]:nil;
    self.board=[[MCBoard alloc]initWithLevel:[MCLevel levelWithDictionary:self.currentLevelInfo]];self.moves=[NSMutableArray new];
    for(id record in restore?saved[@"moves"]:@[]){if(![self.class replayMove:record onBoard:self.board])break;[self.moves addObject:record];}
    [self save];
}
- (void)restoreDailyMoves:(NSArray *)moves {
    self.board=[[MCBoard alloc]initWithLevel:[MCLevel levelWithDictionary:self.currentLevelInfo]];self.moves=[NSMutableArray new];
    for(id record in moves){if(![self.class replayMove:record onBoard:self.board])break;[self.moves addObject:record];}
    self.dailyVisualState=nil;[self save];
}
- (NSTimeInterval)dailyRemainingAtDate:(NSDate *)date {return self.dailyFailed?0:(_dailyAdBreakToken?_dailyAdBreakRemaining:MAX(0,self.dailyDeadline-date.timeIntervalSince1970));}
- (BOOL)dailyAdBreakActive {return _dailyAdBreakToken!=nil;}
- (NSString *)beginDailyAdBreakAtDate:(NSDate *)date {
    if(!self.dailyMode||_dailyFinished||_dailyAdBreakToken||[self dailyRemainingAtDate:date]<=0)return nil;
    _dailyAdBreakRemaining=[self dailyRemainingAtDate:date];
    _dailyAdBreakToken=NSUUID.UUID.UUIDString;
    return _dailyAdBreakToken;
}
- (BOOL)endDailyAdBreak:(NSString *)token rewardSeconds:(NSTimeInterval)seconds atDate:(NSDate *)date {
    if(!token||![_dailyAdBreakToken isEqual:token]||!self.dailyMode||self.dailyFailed||_dailyFinished)return NO;
    if(!isfinite(seconds)||seconds<0)return NO;
    _dailyDeadline=date.timeIntervalSince1970+_dailyAdBreakRemaining+seconds;
    _dailyAdBreakToken=nil;_dailyAdBreakRemaining=0;[self save];
    return YES;
}
- (void)failDaily {_dailyFailed=YES;[self save];}
- (void)save {
    if(self.dailyMode){
        if(_dailyFinished)return;
        NSMutableDictionary *save=[@{@"day":_dailyDay,@"index":@(_dailyIndex),@"deadline":@(_dailyDeadline),@"failed":@(_dailyFailed),@"moves":self.moves,@"revision":@1,@"testTimer":@(_dailyTestTimer)} mutableCopy];
        if(self.dailyVisualState)save[@"visual"]=self.dailyVisualState;
        [NSUserDefaults.standardUserDefaults setObject:save forKey:@"atelier.dailyAttempt"];
    }else [NSUserDefaults.standardUserDefaults setObject:@{@"level":@(self.levelIndex),@"moves":self.moves,@"revision":@2,@"contentRevision":self.catalog[self.levelIndex][@"contentRevision"]?:@0} forKey:@"atelier.session"];
}
- (void)completeCurrentLevel {
    if(self.dailyMode){
        NSTimeInterval remaining=[self dailyRemainingAtDate:NSDate.date];if(remaining<=0)return;
        _dailyFinished=YES;
        [self.dailyStore recordCompletionForDay:_dailyDay remaining:remaining];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"atelier.dailyAttempt"];return;
    }
    [self.completed addObject:self.catalog[self.levelIndex][@"id"]];[NSUserDefaults.standardUserDefaults setObject:self.completed.allObjects forKey:@"atelier.completed"];[NSUserDefaults.standardUserDefaults removeObjectForKey:@"atelier.session"];
}
@end
