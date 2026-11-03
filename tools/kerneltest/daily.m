#import <Foundation/Foundation.h>
#import "MCGameSession.h"
#import "MCVolleyTimeline.h"
int main(void){@autoreleasepool {
    NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:@"atelier.dailyAttempt"];
    MCGameSession *session=[MCGameSession new];NSCAssert(session.dailyStore.levels.count==10,@"Daily catalog missing");
    NSArray *levels=session.dailyStore.levels;
    for(NSDictionary *info in levels){
        MCBoard *board=[[MCBoard alloc]initWithLevel:[MCLevel levelWithDictionary:info]];
        MCVolleyTimeline *timeline=[[MCVolleyTimeline alloc]initWithBoard:board];
        NSUInteger cursor=0,ticks=0;NSMutableSet *hits=[NSMutableSet new];double nextLoad=0;
        while((!board.isWin||timeline.running)&&ticks<20000){
            double time=ticks*.05;
            if(cursor<[info[@"solution"] count]&&time>=nextLoad){
                for(NSInteger slot=0;slot<board.level.slotCount;slot++)if(board.slots[slot]==NSNull.null&&![timeline isSlotAnimating:slot]){
                    NSInteger pick=[info[@"solution"][cursor] integerValue];NSCAssert([board.selectableQueueIndexes containsObject:@(pick)],@"Invisible witness");
                    MCMove *move=[board playBasketAtQueueIndex:pick slotIndex:slot];NSCAssert(move,@"Invalid witness");[timeline enqueueMove:move];cursor++;nextLoad=time+.4;break;
                }
            }
            [timeline advance:.05];ticks++;
            for(MCVolleyShot *hit in timeline.impacts){NSCAssert(![hits containsObject:@(hit.index)],@"Duplicate resumed impact");[hits addObject:@(hit.index)];}
            if(ticks%37==0){
                NSData *data=[NSPropertyListSerialization dataWithPropertyList:timeline.snapshot format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
                MCVolleyTimeline *resumed=[[MCVolleyTimeline alloc]initWithBoard:board];
                NSCAssert([resumed restoreSnapshot:[NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil]],@"Snapshot failed");timeline=resumed;
            }
        }
        NSCAssert(board.isWin&&timeline.colors.count==0,@"Daily witness failed");
        NSCAssert(ticks*.05<[info[@"timeLimit"] doubleValue],@"Deadline impossible for witness");
        printf("%s: %.2fs with 0.4s input spacing, %lu distinct impacts, snapshot resume every 1.85s\n",[info[@"id"] UTF8String],ticks*.05,(unsigned long)hits.count);
    }
    NSDate *now=NSDate.date;[session startDailyAtDate:now reset:YES];double deadline=session.dailyDeadline;
    MCVolleyTimeline *active=[[MCVolleyTimeline alloc]initWithBoard:session.board];NSNumber *firstPick=session.currentLevelInfo[@"solution"][0];
    MCMove *move=[session.board playBasketAtQueueIndex:firstPick.integerValue slotIndex:0];[session.moves addObject:@{@"pick":firstPick,@"slot":@0}];[active enqueueMove:move];[active advance:.2];
    session.dailyVisualState=active.snapshot;[session save];
    MCGameSession *resumed=[MCGameSession new];[resumed startDailyAtDate:[now dateByAddingTimeInterval:10] reset:NO];
    NSCAssert(resumed.dailyDeadline==deadline&&resumed.dailyVisualState&&resumed.moves.count==1,@"Resume reset timer or lost visual state");
    [resumed restoreDailyMoves:@[]];NSCAssert(resumed.dailyDeadline==deadline,@"Undo resets deadline");
    NSCAssert([resumed dailyRemainingAtDate:[now dateByAddingTimeInterval:1000]]==0,@"Deadline did not expire");
    [resumed failDaily];NSCAssert([resumed dailyRemainingAtDate:now]==0,@"Failed daily still playable");
    // Entering from home resumes only a live attempt, never a failed or expired one.
    NSDate *later=[now dateByAddingTimeInterval:1];[resumed startDailyAtDate:later reset:NO];
    NSCAssert(!resumed.dailyFailed&&resumed.moves.count==0&&resumed.dailyVisualState==nil,@"Home restored a failed attempt");
    NSCAssert(fabs([resumed dailyRemainingAtDate:later]-[resumed.currentLevelInfo[@"timeLimit"] doubleValue])<.001,@"Retry has a short clock");
    later=[now dateByAddingTimeInterval:1000];[resumed startDailyAtDate:later reset:NO];
    NSCAssert(fabs([resumed dailyRemainingAtDate:later]-[resumed.currentLevelInfo[@"timeLimit"] doubleValue])<.001,@"Home restored an expired attempt");
    [resumed startDailyAtDate:now reset:YES];
    NSMutableDictionary *testSave=[[defaults dictionaryForKey:@"atelier.dailyAttempt"] mutableCopy];testSave[@"testTimer"]=@YES;testSave[@"deadline"]=@(now.timeIntervalSince1970+8);[defaults setObject:testSave forKey:@"atelier.dailyAttempt"];
    [defaults setObject:@8 forKey:@"MCDailySeconds"];[defaults setObject:@YES forKey:@"MCUITesting"];
    [resumed startDailyAtDate:now reset:NO];
    NSCAssert(fabs([resumed dailyRemainingAtDate:now]-[resumed.currentLevelInfo[@"timeLimit"] doubleValue])<.001,@"Test attempt/preference leaked into normal play");
    [defaults removeObjectForKey:@"MCDailySeconds"];[defaults removeObjectForKey:@"MCUITesting"];
    NSUInteger campaignCount=resumed.completed.count;
    for(NSNumber *pick in resumed.currentLevelInfo[@"solution"])NSCAssert([resumed.board playBasketAtQueueIndex:pick.integerValue],@"Daily completion route failed");
    NSCAssert(resumed.board.isWin,@"Completion must follow a solved board");[resumed completeCurrentLevel];[resumed save];
    NSCAssert(![defaults dictionaryForKey:@"atelier.dailyAttempt"]&&resumed.completed.count==campaignCount,@"Completion restored attempt or changed campaign");
    // Content revisions protect a resumed campaign from old ammo indexes.
    NSDictionary *campaignSave=[defaults dictionaryForKey:@"atelier.session"];NSUInteger completedBefore=resumed.completed.count;
    [resumed start:0 moves:@[@0]];NSInteger remaining=resumed.board.remainingBlockCount;
    MCGameSession *campaignResume=[MCGameSession new];[campaignResume resumeCampaign];
    NSCAssert(campaignResume.moves.count==1&&campaignResume.board.remainingBlockCount==remaining,@"Current campaign save lost its moves");
    NSMutableDictionary *legacy=[[defaults dictionaryForKey:@"atelier.session"] mutableCopy];[legacy removeObjectForKey:@"contentRevision"];[defaults setObject:legacy forKey:@"atelier.session"];
    [campaignResume resumeCampaign];NSCAssert(campaignResume.levelIndex==0&&campaignResume.moves.count==0,@"Old ammo replayed against new content");
    NSCAssert(campaignResume.completed.count==completedBefore,@"Content upgrade erased completion progress");
    if(campaignSave)[defaults setObject:campaignSave forKey:@"atelier.session"];else [defaults removeObjectForKey:@"atelier.session"];
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
    NSCalendar *cal=[[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];cal.timeZone=NSTimeZone.localTimeZone;
    NSDateComponents *c=[NSDateComponents new];c.year=2026;c.month=10;c.day=29;c.hour=12;NSDate *start=[cal dateFromComponents:c];NSInteger first=[session.dailyStore indexForDate:start];
    for(NSInteger i=0;i<=12;i++){NSDate *date=[cal dateByAddingUnit:NSCalendarUnitDay value:i toDate:start options:0];NSCAssert([session.dailyStore indexForDate:date]==(first+i)%10,@"Daily rotation broke across DST");}
    printf("PASS: 10 timed routes, snapshot round trips, deadline persistence, retry, daily/campaign isolation, 10-day rotation across DST, direct-entry expiry/retry, test clock isolation, campaign content migration.\n");
}return 0;}
