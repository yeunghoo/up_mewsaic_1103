#import <Foundation/Foundation.h>
#import "MCVolleyTimeline.h"
int main(void){@autoreleasepool {
 NSArray *catalog=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:@"loop_miao/Content/campaign.json"] options:0 error:nil];
 NSMutableArray<NSNumber *> *costs=[NSMutableArray new];NSInteger impacts=0;
 for(int run=0;run<4;run++)for(NSNumber *index in @[@0,@99,@199]){
  MCBoard *board=[[MCBoard alloc]initWithLevel:[MCLevel levelWithDictionary:catalog[index.integerValue]]];MCVolleyTimeline *timeline=[[MCVolleyTimeline alloc]initWithBoard:board];
  NSInteger ticks=0;
  while((!board.isWin||timeline.running)&&ticks++<60000){@autoreleasepool {
   for(NSInteger slot=0;slot<board.level.slotCount;slot++)if(board.slots[slot]==NSNull.null&&![timeline isSlotAnimating:slot]&&board.selectableQueueIndexes.count)[timeline enqueueMove:[board playBasketAtQueueIndex:board.selectableQueueIndexes.firstObject.integerValue slotIndex:slot]];
   NSTimeInterval start=NSProcessInfo.processInfo.systemUptime;[timeline advance:1.0/60];
   [costs addObject:@((NSProcessInfo.processInfo.systemUptime-start)*1000)];impacts+=timeline.impacts.count;
  }}NSCAssert(board.isWin&&!timeline.running,@"Stalled performance route");
 }
 NSArray *sorted=[costs sortedArrayUsingSelector:@selector(compare:)];double total=0;for(NSNumber *n in costs)total+=n.doubleValue;
 printf("advance CPU: %lu ticks, %ld impacts, mean %.4fms, p95 %.4fms, p99 %.4fms, max %.4fms\n",(unsigned long)costs.count,(long)impacts,total/costs.count,[sorted[sorted.count*95/100] doubleValue],[sorted[sorted.count*99/100] doubleValue],[sorted.lastObject doubleValue]);
}return 0;}
