#import "MCImpactBurst.h"
@implementation MCImpactBurst {
    CALayer *_root, *_flash;
    NSArray<CALayer *> *_fragments;
    CAAnimationGroup *_flashAnimation;
    NSArray<CAAnimationGroup *> *_fragmentAnimations;
}
- (instancetype)initWithParent:(CALayer *)parent {
    if((self=[super init])){
        _root=[CALayer layer];[parent addSublayer:_root];
        _flash=[CALayer layer];_flash.bounds=CGRectMake(0,0,18,18);_flash.cornerRadius=9;_flash.backgroundColor=UIColor.whiteColor.CGColor;_flash.opacity=0;[_root addSublayer:_flash];
        CABasicAnimation *fade=[CABasicAnimation animationWithKeyPath:@"opacity"];fade.fromValue=@.9;fade.toValue=@0;fade.duration=.18;
        CABasicAnimation *scale=[CABasicAnimation animationWithKeyPath:@"transform.scale"];scale.fromValue=@.65;scale.toValue=@1.6;scale.duration=.18;
        _flashAnimation=[CAAnimationGroup animation];_flashAnimation.animations=@[fade,scale];_flashAnimation.duration=.18;
        NSMutableArray *layers=[NSMutableArray new],*animations=[NSMutableArray new];
        for(int i=0;i<4;i++){
            CGFloat angle=(i+.5)*M_PI_2;CALayer *fragment=[CALayer layer];fragment.bounds=CGRectMake(0,0,5,5);fragment.cornerRadius=1.5;fragment.opacity=0;fragment.transform=CATransform3DMakeRotation(angle,0,0,1);[_root addSublayer:fragment];[layers addObject:fragment];
            CABasicAnimation *travel=[CABasicAnimation animationWithKeyPath:@"position"];travel.duration=.26;travel.fromValue=[NSValue valueWithCGPoint:CGPointZero];travel.toValue=[NSValue valueWithCGPoint:CGPointMake(cos(angle)*18,sin(angle)*18+8)];
            CABasicAnimation *fade=[CABasicAnimation animationWithKeyPath:@"opacity"];fade.fromValue=@1;fade.toValue=@0;fade.duration=.26;
            CAAnimationGroup *group=[CAAnimationGroup animation];group.animations=@[travel,fade];group.duration=.26;group.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];[animations addObject:group];
        }
        _fragments=layers;_fragmentAnimations=animations;
    }return self;
}
- (void)emitAt:(CGPoint)point color:(UIColor *)color {
    _root.position=point;[_flash addAnimation:_flashAnimation forKey:@"impact"];
    for(NSInteger i=0;i<_fragments.count;i++){CALayer *part=_fragments[i];part.backgroundColor=color.CGColor;[part addAnimation:_fragmentAnimations[i] forKey:@"impact"];}
}
- (void)clear {[_flash removeAllAnimations];for(CALayer *part in _fragments)[part removeAllAnimations];}
@end
