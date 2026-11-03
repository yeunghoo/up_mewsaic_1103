#import "MCShotEffects.h"
#import "MCArtworkView.h"
#import "MCVisuals.h"
#import "MCPalette.h"
#import "MCSoundPlayer.h"
#import "MCImpactBurst.h"
@interface MCProjectileNode : NSObject
@property(nonatomic,strong) CALayer *layer;
@property(nonatomic) CGPoint origin,target;
@end
@implementation MCProjectileNode
@end
@implementation MCShotEffects {
    UIView *_overlay;
    MCArtworkView *_art;
    NSArray<MCCannonView *> *_cannons;
    NSMutableDictionary<NSNumber *,MCProjectileNode *> *_projectiles;
    NSMutableArray<MCProjectileNode *> *_freeProjectiles;
    NSDictionary<NSString *,UIImage *> *_sprites;
    NSArray<MCImpactBurst *> *_bursts;
    NSUInteger _nextBurst;
    UIImpactFeedbackGenerator *_haptic;
    NSTimeInterval _lastHaptic;
}
- (instancetype)initWithHost:(UIView *)host artwork:(MCArtworkView *)art cannons:(NSArray *)cannons {
    if((self=[super init])){
        _art=art;_cannons=[cannons copy];_projectiles=[NSMutableDictionary new];_freeProjectiles=[NSMutableArray new];
        _overlay=[[UIView alloc]initWithFrame:host.bounds];_overlay.userInteractionEnabled=NO;
        _overlay.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[host addSubview:_overlay];
        NSMutableDictionary *sprites=[NSMutableDictionary new];
        for(NSString *key in @[@"B",@"Y",@"P",@"G",@"L",@"W",@"R",@"K"]){
            UIColor *color=[MCPalette colorForKey:key];UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithSize:CGSizeMake(20,25)];
            sprites[key]=[renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx){
                CGContextSetShadowWithColor(ctx.CGContext,CGSizeZero,3,[color colorWithAlphaComponent:.45].CGColor);
                CGRect ball=CGRectMake(4,4,12,15);MCFillRounded(CGRectOffset(ball,0,2),6,MCShade(color,-.3));
                CGContextSetShadowWithColor(ctx.CGContext,CGSizeZero,0,nil);MCFillShaded(ball,6,color);MCFillRounded(CGRectMake(6,6,3,5),1.5,[UIColor colorWithWhite:1 alpha:.85]);
            }];
        }_sprites=sprites;
        // At most three in-flight rounds per lane at the supported cadence; reserve four.
        for(NSUInteger i=0;i<cannons.count*4;i++){MCProjectileNode *node=[MCProjectileNode new];node.layer=[CALayer layer];node.layer.bounds=CGRectMake(0,0,20,25);node.layer.hidden=YES;[_overlay.layer addSublayer:node.layer];[_freeProjectiles addObject:node];}
        NSMutableArray *bursts=[NSMutableArray new];for(int i=0;i<20;i++)[bursts addObject:[[MCImpactBurst alloc]initWithParent:_overlay.layer]];_bursts=bursts;
        _haptic=[[UIImpactFeedbackGenerator alloc]initWithStyle:UIImpactFeedbackStyleLight];
        [MCSoundPlayer shared]; // Begin asynchronous preparation before the first tap.
    }return self;
}
- (CGPoint)target:(NSInteger)index {
    MCLevel *l=_art.level;CGFloat cell=MIN((_art.bounds.size.width-24)/l.cols,(_art.bounds.size.height-24)/l.rows);
    CGPoint p=CGPointMake((_art.bounds.size.width-cell*l.cols)/2+(index%l.cols+.5)*cell,(_art.bounds.size.height-cell*l.rows)/2+(index/l.cols+.5)*cell);
    return [_art convertPoint:p toView:_overlay];
}
- (void)renderTimeline:(MCVolleyTimeline *)timeline {
    BOOL reduced=UIAccessibilityIsReduceMotionEnabled();NSArray *flying=timeline.flying;
    [CATransaction begin];[CATransaction setDisableActions:YES];
    // Release hits first, so even a same-frame reload never needs a new layer.
    for(MCVolleyShot *shot in timeline.impacts){
        MCProjectileNode *node=_projectiles[@(shot.index)];if(node){node.layer.hidden=YES;[_freeProjectiles addObject:node];[_projectiles removeObjectForKey:@(shot.index)];}
        if(!reduced){[_bursts[_nextBurst] emitAt:[self target:shot.index] color:[MCPalette colorForKey:shot.color]];_nextBurst=(_nextBurst+1)%_bursts.count;}
    }
    for(MCVolleyShot *shot in timeline.launched){MCCannonView *cannon=_cannons[shot.slot];[cannon consumeShot];if(!reduced)[cannon land];}
    for(MCVolleyShot *shot in flying){
        MCProjectileNode *node=_projectiles[@(shot.index)];
        if(reduced){node.layer.hidden=YES;continue;}
        if(!node&&_freeProjectiles.count){
            node=_freeProjectiles.lastObject;[_freeProjectiles removeLastObject];_projectiles[@(shot.index)]=node;
            MCCannonView *cannon=_cannons[shot.slot];node.origin=[cannon convertPoint:CGPointMake(cannon.bounds.size.width/2,5) toView:_overlay];node.target=[self target:shot.index];
            node.layer.contents=(id)_sprites[shot.color].CGImage;
            node.layer.transform=CATransform3DMakeRotation(atan2(node.target.y-node.origin.y,node.target.x-node.origin.x)+M_PI_2,0,0,1);
        }
        if(node){CGFloat t=shot.progress*shot.progress;node.layer.hidden=NO;node.layer.position=CGPointMake(node.origin.x+(node.target.x-node.origin.x)*t,node.origin.y+(node.target.y-node.origin.y)*t);}
    }
    [CATransaction commit];
    // Coalesce simultaneous shots/impacts before crossing into the audio queue.
    if(timeline.launched.count)[[MCSoundPlayer shared]play:@"shot"];
    if(timeline.impacts.count){
        [[MCSoundPlayer shared]play:@"hit"];NSTimeInterval now=CACurrentMediaTime();
        if(now-_lastHaptic>.18&&[NSUserDefaults.standardUserDefaults boolForKey:@"atelier.haptics"]){[_haptic impactOccurredWithIntensity:.4];_lastHaptic=now;}
    }
}
- (void)clear {for(MCProjectileNode *node in _projectiles.allValues){node.layer.hidden=YES;[_freeProjectiles addObject:node];}[_projectiles removeAllObjects];for(MCImpactBurst *burst in _bursts)[burst clear];[_overlay removeFromSuperview];}
@end
