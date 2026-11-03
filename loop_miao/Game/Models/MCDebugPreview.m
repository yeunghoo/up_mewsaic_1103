#import "MCDebugPreview.h"
#if DEBUG
#import "MCGameSession.h"
#import "MCGameViewController.h"
@implementation MCDebugPreview
+ (NSInteger)configure:(MCGameSession *)session {
    NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;
    NSString *scene=[defaults stringForKey:@"MCStoreScene"];
    if([defaults boolForKey:@"MCPreviewTail"]){
        [session start:0 moves:@[]];while(session.board.visibleQueueIndexes.count>1){NSNumber *pick=session.board.selectableQueueIndexes.firstObject;if(!pick||![session.board playBasketAtQueueIndex:pick.integerValue])break;[session.moves addObject:pick];}return MCScreenBattle;
    }
    if([scene isEqual:@"daily-win"]){
        [session startDailyAtDate:NSDate.date reset:YES];for(NSNumber *pick in session.currentLevelInfo[@"solution"]){[session.board playBasketAtQueueIndex:pick.integerValue];[session.moves addObject:pick];}[session completeCurrentLevel];return MCScreenResults;
    }
    NSDictionary *arguments=[defaults volatileDomainForName:NSArgumentDomain];
    if([arguments[@"MCUITesting"] boolValue]&&[arguments[@"MCSeedExpiredDaily"] boolValue]){
        [session startDailyAtDate:NSDate.date reset:YES];
        NSMutableDictionary *saved=[[defaults dictionaryForKey:@"atelier.dailyAttempt"] mutableCopy];
        saved[@"deadline"]=@(NSDate.date.timeIntervalSince1970-1);[defaults setObject:saved forKey:@"atelier.dailyAttempt"];
        return MCScreenHome;
    }
    if([scene isEqual:@"home"])return MCScreenHome;
    if([scene isEqual:@"map"])return MCScreenMap;
        if([scene isEqual:@"daily"]||[scene isEqual:@"daily-battle"]||[defaults boolForKey:@"MCPreviewDaily"]){
        [session startDailyAtDate:NSDate.date reset:![defaults boolForKey:@"MCResumeDaily"]];return MCScreenBattle;
    }
    if([scene isEqual:@"battle"]||[scene isEqual:@"win"]){
        [session start:0 moves:@[]];
        if([scene isEqual:@"win"]){while(!session.board.isWin&&!session.board.isDeadlock&&session.board.selectableQueueIndexes.count){NSNumber *pick=session.board.selectableQueueIndexes.firstObject;[session.board playBasketAtQueueIndex:pick.integerValue];[session.moves addObject:pick];}[session completeCurrentLevel];return MCScreenResults;}
        return MCScreenBattle;
    }
    return -1;
}
@end
#endif
