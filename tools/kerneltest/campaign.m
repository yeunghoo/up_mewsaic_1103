#import <Foundation/Foundation.h>
#import "MCBoard.h"
int main(void){@autoreleasepool {
    NSArray *levels=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:@"loop_miao/Content/campaign.json"] options:0 error:nil];
    NSArray *reports=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:@"tools/levelgen/campaign_validation.json"] options:0 error:nil];
    NSCAssert(levels.count==200 && reports.count==200,@"Missing campaign");NSInteger steps=0;
    for(NSUInteger n=0;n<levels.count;n++){
        MCLevel *l=[MCLevel levelWithDictionary:levels[n]];MCBoard *b=[[MCBoard alloc]initWithLevel:l];
        NSMutableDictionary *counts=[NSMutableDictionary new];
        for(NSString *row in l.pattern)for(NSUInteger c=0;c<row.length;c++){NSString *k=[row substringWithRange:NSMakeRange(c,1)];if(![k isEqual:@"."])counts[k]=@([counts[k] integerValue]+1);}
        for(MCBasketSpec *s in l.baskets)counts[s.colorKey]=@([counts[s.colorKey] integerValue]-s.capacity);
        for(NSNumber *count in counts.allValues)NSCAssert(count.integerValue==0,@"Capacity mismatch");
        NSArray *trace=reports[n][@"trace"];
        for(NSUInteger i=0;i<l.baskets.count;i++){
            NSCAssert([b playBasketAtQueueIndex:i]!=nil,@"Illegal solution step");
            NSCAssert(b.remainingBlockCount==[trace[i][@"remaining"] integerValue],@"Python / Objective-C board mismatch");
            NSArray *expected=trace[i][@"slots"];
            for(NSUInteger s=0;s<expected.count;s++){
                if(expected[s]==NSNull.null)NSCAssert(b.slots[s]==NSNull.null,@"Slot should empty");
                else {MCBasket *actual=b.slots[s];NSArray *e=expected[s];NSCAssert([actual.colorKey isEqual:e[0]]&&actual.filled==[e[1] integerValue]&&actual.capacity==[e[2] integerValue],@"Slot mismatch");}
            }steps++;
        }
        NSCAssert(b.isWin&&!b.isDeadlock&&b.pendingQueueIndexes.count==0,@"Unsolved board");
        [b reset];NSCAssert(b.remainingBlockCount==[reports[n][@"blocks"] integerValue],@"Reset mismatch");
    }
    // Exercise the newly supported upper mask bits with 64 separate baskets.
    NSMutableArray *baskets=[NSMutableArray new];for(int i=0;i<64;i++)[baskets addObject:@{@"color":@"R",@"capacity":@1}];
    MCLevel *wide=[MCLevel levelWithDictionary:@{@"id":@"64-basket-test",@"slots":@5,@"window":@5,@"preview":@5,@"pattern":@[@"RRRRRRRR",@"RRRRRRRR",@"RRRRRRRR",@"RRRRRRRR",@"RRRRRRRR",@"RRRRRRRR",@"RRRRRRRR",@"RRRRRRRR"],@"baskets":baskets}];
    MCBoard *board=[[MCBoard alloc]initWithLevel:wide];for(int i=0;i<64;i++)NSCAssert([board playBasketAtQueueIndex:i],@"64-bit queue regression");NSCAssert(board.isWin,@"64-basket win");
    printf("PASS: 200 levels, %ld independent trace steps, capacity conservation, resets and 64-basket regression.\n",(long)steps);
}return 0;}
