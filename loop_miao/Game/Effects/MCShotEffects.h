#import <UIKit/UIKit.h>
#import "MCVolleyTimeline.h"
@class MCArtworkView, MCCannonView;
@interface MCShotEffects : NSObject
- (instancetype)initWithHost:(UIView *)host artwork:(MCArtworkView *)art cannons:(NSArray<MCCannonView *> *)cannons;
- (void)renderTimeline:(MCVolleyTimeline *)timeline;
- (void)clear;
@end
