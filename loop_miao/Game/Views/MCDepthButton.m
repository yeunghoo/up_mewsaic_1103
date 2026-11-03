#import "MCDepthButton.h"
#import "MCVisuals.h"
@implementation MCDepthButton
- (instancetype)initWithFrame:(CGRect)frame {if((self=[super initWithFrame:frame])){self.backgroundColor=UIColor.clearColor;self.opaque=NO;self.contentMode=UIViewContentModeRedraw;self.layer.shadowColor=[UIColor colorWithRed:.08 green:.18 blue:.18 alpha:1].CGColor;self.layer.shadowOffset=CGSizeMake(0,5);self.layer.shadowRadius=5;self.layer.shadowOpacity=.16;}return self;}
- (void)setConfiguration:(UIButtonConfiguration *)config {
    self.surfaceColor=config.baseBackgroundColor?:[UIColor colorWithRed:.1 green:.25 blue:.26 alpha:1];
    UIButtonConfiguration *c=[config copy];c.background.backgroundColor=UIColor.clearColor;
    [super setConfiguration:c];[self setNeedsDisplay];
}
- (void)setBasketStyle:(BOOL)basketStyle {_basketStyle=basketStyle;[self setNeedsDisplay];}
- (void)drawRect:(CGRect)rect {
    UIColor *color=self.surfaceColor?:UIColor.darkGrayColor;
    if(self.basketStyle){MCDrawMagazine(rect,color);return;}
    CGRect body=CGRectInset(rect,1,1);body.size.height-=4;
    MCFillRounded(CGRectOffset(body,0,4),16,MCShade(color,-.38));MCFillShaded(body,16,color);
    UIBezierPath *edge=[UIBezierPath bezierPathWithRoundedRect:CGRectInset(body,.7,.7) cornerRadius:15];[[UIColor colorWithWhite:1 alpha:.2] setStroke];edge.lineWidth=1;[edge stroke];
}
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:highlighted?.09:.28 delay:0 usingSpringWithDamping:.62 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{self.transform=highlighted?CGAffineTransformMakeTranslation(0,3):CGAffineTransformIdentity;self.layer.shadowOpacity=highlighted?.04:.16;} completion:nil];
}
@end
