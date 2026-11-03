#import "MCMapView.h"
#import "MCVisuals.h"
@implementation MCMapView
- (void)build {
    self.backgroundColor=[UIColor colorWithRed:.82 green:.94 blue:.88 alpha:1];self.layer.cornerRadius=28;self.clipsToBounds=YES;self.contentMode=UIViewContentModeRedraw;
    for(UIView *v in self.subviews)[v removeFromSuperview];
    for(NSInteger i=0;i<20;i++){
        MCDepthButton *b=[MCDepthButton buttonWithType:UIButtonTypeCustom];NSInteger level=self.firstLevel+i;
        BOOL done=[self.finishedLevels containsObject:@(level)];UIButtonConfiguration *c=[UIButtonConfiguration filledButtonConfiguration];
        c.title=done?@"★":[NSString stringWithFormat:@"%ld",(long)level+1];c.baseBackgroundColor=done?[UIColor colorWithRed:.98 green:.73 blue:.24 alpha:1]:level==self.unlockedLevel?[UIColor colorWithRed:.98 green:.39 blue:.39 alpha:1]:[UIColor colorWithRed:.45 green:.68 blue:.65 alpha:1];c.baseForegroundColor=UIColor.whiteColor;c.contentInsets=NSDirectionalEdgeInsetsZero;b.configuration=c;b.tag=level;b.enabled=level<=self.unlockedLevel;b.alpha=b.enabled?1:.78;
        b.accessibilityLabel=[NSString stringWithFormat:@"Level %ld%@",(long)level+1,done?@", completed":b.enabled?@", unlocked":@", locked"];
        b.accessibilityIdentifier=[NSString stringWithFormat:@"level-%ld",(long)level+1];[b addTarget:self.target action:self.action forControlEvents:UIControlEventTouchUpInside];[self addSubview:b];
    }
}
- (CGPoint)point:(NSInteger)i {
    NSInteger row=i/4,col=row%2?3-i%4:i%4;
    return CGPointMake(34+(self.bounds.size.width-68)*col/3,30+(self.bounds.size.height-60)*row/4);
}
- (void)layoutSubviews {[super layoutSubviews];for(UIButton *b in self.subviews){b.bounds=CGRectMake(0,0,46,46);b.center=[self point:b.tag-self.firstLevel];}[self setNeedsDisplay];}
- (void)drawRect:(CGRect)rect {
    CGFloat w=rect.size.width,h=rect.size.height;
    [[UIColor colorWithRed:.69 green:.87 blue:.77 alpha:1]setFill];[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(-60,h*.35,w*.8,h*.8)]fill];
    [[UIColor colorWithRed:.75 green:.9 blue:.82 alpha:1]setFill];[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(w*.5,-30,w*.7,h*.8)]fill];
    // Small illustrated landmarks fill the spaces between the route's five rows.
    for(int row=0;row<4;row++){
        CGFloat cy=30+(h-60)*(row+.5)/4, cx=w*(row%2?.68:.32);
        MCFillRounded(CGRectMake(cx-37,cy+14,74,12),6,[UIColor colorWithRed:.3 green:.6 blue:.44 alpha:.18]);
        for(int tree=0;tree<3;tree++){
            CGFloat tx=cx-27+tree*26,ty=cy+(tree%2?2:-6);
            MCFillRounded(CGRectMake(tx-2,ty,5,25),2,[UIColor colorWithRed:.63 green:.42 blue:.25 alpha:1]);
            UIColor *leaf=tree%2?[UIColor colorWithRed:.27 green:.66 blue:.49 alpha:1]:[UIColor colorWithRed:.43 green:.76 blue:.47 alpha:1];
            [MCShade(leaf,-.18)setFill];[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(tx-13,ty-17,28,28)]fill];
            [leaf setFill];[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(tx-14,ty-22,26,27)]fill];
            [MCShade(leaf,.25)setFill];[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(tx-9,ty-19,9,7)]fill];
        }
        NSString *landmark=@[@"✿",@"★",@"✿",@"⚑"][row];
        [landmark drawAtPoint:CGPointMake(w-cx-12,cy-13) withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:27 weight:UIFontWeightBold],NSForegroundColorAttributeName:[UIColor colorWithRed:.97 green:.64 blue:.25 alpha:1]}];
    }
    UIBezierPath *route=[UIBezierPath bezierPath];[route moveToPoint:[self point:0]];for(int i=1;i<20;i++)[route addLineToPoint:[self point:i]];
    route.lineCapStyle=kCGLineCapRound;route.lineJoinStyle=kCGLineJoinRound;route.lineWidth=17;[[UIColor colorWithRed:.48 green:.72 blue:.61 alpha:.5]setStroke];[route stroke];route.lineWidth=11;[[UIColor colorWithRed:1 green:.96 blue:.79 alpha:1]setStroke];[route stroke];
    for(int i=0;i<8;i++){CGFloat x=15+fmod(i*91,w-30),y=57+fmod(i*73,MAX(1,h-110));[[UIColor colorWithRed:1 green:1 blue:.9 alpha:.65]setFill];[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x,y,5,5)]fill];}
}
@end
