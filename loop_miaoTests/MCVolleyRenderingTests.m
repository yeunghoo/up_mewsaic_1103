#import <XCTest/XCTest.h>
#import "MCArtworkView.h"
#import "MCCannonView.h"
#import "MCShotEffects.h"
#import "MCPalette.h"

@interface MCVolleyRenderingTests : XCTestCase
@end
@implementation MCVolleyRenderingTests
- (void)collectLayers:(CALayer *)layer into:(NSMutableSet *)layers {
    [layers addObject:layer];for(CALayer *child in layer.sublayers)[self collectLayers:child into:layers];
}
- (void)testDenseVolleyReusesAllEffectLayers {
    NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;
    BOOL sound=[defaults boolForKey:@"atelier.sound"],haptics=[defaults boolForKey:@"atelier.haptics"];
    [defaults setBool:NO forKey:@"atelier.sound"];[defaults setBool:NO forKey:@"atelier.haptics"];
    NSArray *catalog=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"campaign" withExtension:@"json"]] options:0 error:nil];
    MCBoard *board=[[MCBoard alloc]initWithLevel:[MCLevel levelWithDictionary:catalog[199]]];MCVolleyTimeline *timeline=[[MCVolleyTimeline alloc]initWithBoard:board];
    UIView *host=[[UIView alloc]initWithFrame:CGRectMake(0,0,390,844)];
    MCArtworkView *art=[[MCArtworkView alloc]initWithFrame:CGRectMake(20,80,350,500)];art.level=board.level;art.displayedColors=timeline.colors;[host addSubview:art];
    NSMutableArray *cannons=[NSMutableArray new];for(int i=0;i<5;i++){MCCannonView *c=[[MCCannonView alloc]initWithFrame:CGRectMake(20+i*70,600,64,68)];[host addSubview:c];[cannons addObject:c];}
    MCShotEffects *effects=[[MCShotEffects alloc]initWithHost:host artwork:art cannons:cannons];UIView *overlay=host.subviews.lastObject;
    NSMutableSet *original=[NSMutableSet new];[self collectLayers:overlay.layer into:original];
    NSUInteger ticks=0,hits=0,maxFlying=0;BOOL restored=NO;NSMutableArray<NSNumber *> *costs=[NSMutableArray new];
    while((!board.isWin||timeline.running)&&ticks++<20000){@autoreleasepool {
        for(NSInteger slot=0;slot<5;slot++)if(board.slots[slot]==NSNull.null&&![timeline isSlotAnimating:slot]&&board.selectableQueueIndexes.count){
            MCMove *move=[board playBasketAtQueueIndex:board.selectableQueueIndexes.firstObject.integerValue slotIndex:slot];
            [cannons[slot] showColor:[MCPalette colorForKey:move.colorKey] symbol:move.colorKey filled:0 capacity:move.capacity];[timeline enqueueMove:move];
        }
        CFTimeInterval start=CACurrentMediaTime();[timeline advance:1.0/60];[effects renderTimeline:timeline];
        hits+=timeline.impacts.count;maxFlying=MAX(maxFlying,timeline.flying.count);
        [costs addObject:@((CACurrentMediaTime()-start)*1000)];
        if(!restored&&timeline.flying.count>=2){
            MCVolleyTimeline *resumed=[[MCVolleyTimeline alloc]initWithBoard:board];XCTAssertTrue([resumed restoreSnapshot:timeline.snapshot]);timeline=resumed;art.displayedColors=timeline.colors;restored=YES;
            // A new renderer must also construct visible rounds from a restored flight.
            [effects clear];effects=[[MCShotEffects alloc]initWithHost:host artwork:art cannons:cannons];overlay=host.subviews.lastObject;
            [original removeAllObjects];[self collectLayers:overlay.layer into:original];[effects renderTimeline:timeline];
            if(!UIAccessibilityIsReduceMotionEnabled()){NSUInteger visible=0;for(CALayer *layer in overlay.layer.sublayers)if(layer.contents&&!layer.hidden)visible++;XCTAssertEqual(visible,timeline.flying.count);}
        }
    }}
    XCTAssertTrue(board.isWin);XCTAssertFalse(timeline.running);XCTAssertTrue(restored);XCTAssertGreaterThan(hits,500);XCTAssertLessThanOrEqual(maxFlying,20);
    NSMutableSet *final=[NSMutableSet new];[self collectLayers:overlay.layer into:final];XCTAssertEqualObjects(original,final,@"Effects allocated or discarded layers during firing");XCTAssertEqual(overlay.subviews.count,0);
    NSArray *sorted=[costs sortedArrayUsingSelector:@selector(compare:)];NSLog(@"VOLLEY_RENDER_CPU ticks=%lu hits=%lu poolLayers=%lu p95=%.3fms p99=%.3fms",(unsigned long)ticks,(unsigned long)hits,(unsigned long)final.count,[sorted[sorted.count*95/100] doubleValue],[sorted[sorted.count*99/100] doubleValue]);
    [effects clear];XCTAssertNil(overlay.superview);
    [defaults setBool:sound forKey:@"atelier.sound"];[defaults setBool:haptics forKey:@"atelier.haptics"];
}
@end
