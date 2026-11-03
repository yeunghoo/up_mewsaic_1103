#import "MCAmmoStackView.h"
#import "MCVisuals.h"
#import "MCPalette.h"
@implementation MCAmmoStackView
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){self.backgroundColor=UIColor.clearColor;self.opaque=NO;self.contentMode=UIViewContentModeRedraw;self.isAccessibilityElement=YES;self.accessibilityIdentifier=@"ammo-preview";}
    return self;
}
- (void)setPacks:(NSArray *)packs {
    _packs=[packs copy];NSMutableArray *labels=[NSMutableArray new];
    for(MCBasketSpec *p in packs)[labels addObject:[NSString stringWithFormat:@"%@ %ld",[MCPalette nameForKey:p.colorKey],(long)p.capacity]];
    self.accessibilityLabel=[@"Upcoming ammo, " stringByAppendingString:[labels componentsJoinedByString:@", "]];[self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    NSInteger count=self.packs.count;if(!count)return;
    CGFloat width=MIN(64,(rect.size.width-16)/(1+MAX(0,count-1)*.75)),stride=width*.75;
    CGFloat total=width+(count-1)*stride,start=(rect.size.width-total)/2;
    for(NSInteger i=count-1;i>=0;i--){MCBasketSpec *p=self.packs[i];UIColor *color=[MCPalette colorForKey:p.colorKey];
        CGRect card=CGRectMake(start+i*stride,4+MIN(i,3)*2,width,rect.size.height-14);
        MCFillRounded(CGRectOffset(card,0,3),9,MCShade(color,-.3));MCFillShaded(card,9,color);
        UIBezierPath *edge=[UIBezierPath bezierPathWithRoundedRect:card cornerRadius:9];[[UIColor colorWithWhite:1 alpha:.7]setStroke];edge.lineWidth=1.5;[edge stroke];
        NSString *n=[NSString stringWithFormat:@"%ld",(long)p.capacity];NSDictionary *a=@{NSFontAttributeName:[UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightHeavy],NSForegroundColorAttributeName:[MCPalette isLightColorForKey:p.colorKey]?[UIColor colorWithWhite:.12 alpha:1]:UIColor.whiteColor};
        CGSize size=[n sizeWithAttributes:a];[n drawAtPoint:CGPointMake(CGRectGetMidX(card)-size.width/2,CGRectGetMidY(card)-size.height/2) withAttributes:a];
    }
}
@end
