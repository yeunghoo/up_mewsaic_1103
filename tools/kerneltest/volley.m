#import <Foundation/Foundation.h>
#import "MCVolleyTimeline.h"
int main(void){@autoreleasepool {
    NSArray *levels=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:@"loop_miao/Content/campaign.json"] options:0 error:nil];
    NSInteger concurrentFrames=0,shots=0;
    for(NSUInteger n=0;n<levels.count;n++){
        MCLevel *level=[MCLevel levelWithDictionary:levels[n]];MCBoard *board=[[MCBoard alloc]initWithLevel:level];
        MCVolleyTimeline *timeline=[[MCVolleyTimeline alloc]initWithBoard:board];NSMutableArray *records=[NSMutableArray new];
        NSMutableSet *launched=[NSMutableSet new],*hit=[NSMutableSet new];NSInteger ticks=0;
        while((!board.isWin||timeline.running)&&ticks++<60000){
            // Fill every truly available lane while the earlier loads are still in flight.
            for(NSInteger s=0;s<level.slotCount;s++)if(board.slots[s]==NSNull.null&&![timeline isSlotAnimating:s]&&board.selectableQueueIndexes.count){
                NSNumber *pick=board.selectableQueueIndexes.firstObject;MCMove *move=[board playBasketAtQueueIndex:pick.integerValue slotIndex:s];
                NSCAssert(move,@"Concurrent load rejected");[records addObject:@[pick,@(s)]];[timeline enqueueMove:move];
            }
            [timeline advance:.05];NSMutableSet *activeLanes=[NSMutableSet new];
            for(MCVolleyShot *shot in timeline.flying)[activeLanes addObject:@(shot.slot)];
            if(activeLanes.count>1)concurrentFrames++;
            for(MCVolleyShot *shot in timeline.launched){NSCAssert(![launched containsObject:@(shot.index)],@"Double target");[launched addObject:@(shot.index)];}
            for(MCVolleyShot *shot in timeline.impacts){NSCAssert([launched containsObject:@(shot.index)]&&![hit containsObject:@(shot.index)],@"Invalid impact");[hit addObject:@(shot.index)];shots++;}
            NSCAssert(timeline.colors.count+hit.count==[levels[n][@"pattern"] componentsJoinedByString:@""].length-([[levels[n][@"pattern"] componentsJoinedByString:@""] componentsSeparatedByString:@"."].count-1),@"Visual tile conservation");
        }
        NSCAssert(ticks<60000,@"Visual timeline stalled");NSCAssert(board.isWin&&timeline.colors.count==0,@"Concurrent route unsolved");
        MCBoard *replay=[[MCBoard alloc]initWithLevel:level];
        for(NSArray *record in records)NSCAssert([replay playBasketAtQueueIndex:[record[0] integerValue] slotIndex:[record[1] integerValue]],@"Replay rejected");
        NSCAssert(replay.isWin,@"Slot-aware replay failed");
        if(n==0)NSCAssert(level.slotCount==3,@"Tutorial slots");if(n==20)NSCAssert(level.slotCount==4,@"Intermediate slots");if(n==40)NSCAssert(level.slotCount==5,@"Full slots");
    }
    NSCAssert(concurrentFrames>0,@"Cannons did not overlap");
    printf("PASS: 200 concurrent replays, %ld unique impacts, %ld frames with multiple cannons firing.\n",(long)shots,(long)concurrentFrames);
}return 0;}
