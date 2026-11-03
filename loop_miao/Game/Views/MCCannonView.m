#import "MCCannonView.h"
#import "MCVisuals.h"
#import "MCPalette.h"
@implementation MCCannonView {
    UIColor *_color;UILabel *_label;CGFloat _progress;NSInteger _capacity;NSInteger _filled;NSString *_symbol;
    CALayer *_meter;
    UIImage *_bodyImage;
    CGSize _bodySize;
    CAKeyframeAnimation *_recoil;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        self.opaque=NO;self.backgroundColor=UIColor.clearColor;self.contentMode=UIViewContentModeRedraw;
        _label=[UILabel new];_label.font=[UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightBold];_label.textAlignment=NSTextAlignmentCenter;_label.numberOfLines=1;_label.adjustsFontSizeToFitWidth=YES;_label.minimumScaleFactor=.75;[self addSubview:_label];
        _meter=[CALayer layer];_meter.cornerRadius=1;[self.layer addSublayer:_meter];
        _recoil=[CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];_recoil.values=@[@0,@3,@0];_recoil.keyTimes=@[@0,@.3,@1];_recoil.duration=.12;
    }return self;
}
- (void)layoutSubviews {[super layoutSubviews];_label.frame=CGRectMake(3,self.bounds.size.height*.64,self.bounds.size.width-6,self.bounds.size.height*.24);[self updateMeter];}
- (void)updateMeter {
    CGFloat width=MIN(110,self.bounds.size.width);
    [CATransaction begin];[CATransaction setDisableActions:YES];
    _meter.frame=CGRectMake((self.bounds.size.width-width)/2+width*.23,self.bounds.size.height*.91,width*.54*_progress,2);_meter.hidden=_progress<=0;
    [CATransaction commit];
}
- (void)showColor:(UIColor *)color symbol:(NSString *)symbol filled:(NSInteger)filled capacity:(NSInteger)capacity {
    if(_capacity==capacity&&_filled==filled&&[_color isEqual:color])return;
    BOOL repaint=![_color isEqual:color];
    _capacity=capacity;_filled=filled;_symbol=symbol;_color=color;_progress=capacity?1-(CGFloat)filled/capacity:0;
    _label.text=capacity?[NSString stringWithFormat:@"%ld",(long)(capacity-filled)]:@"";
    if(repaint){
        CGFloat r,g,b,a;[color getRed:&r green:&g blue:&b alpha:&a];_label.textColor=r*.299+g*.587+b*.114>.62?[UIColor colorWithWhite:.12 alpha:1]:UIColor.whiteColor;
        [CATransaction begin];[CATransaction setDisableActions:YES];_meter.backgroundColor=MCShade(color,.45).CGColor;[CATransaction commit];_bodyImage=nil;[self setNeedsDisplay];
    }
    self.accessibilityLabel=capacity?[NSString stringWithFormat:@"%@ cannon, %ld shots",[MCPalette nameForKey:symbol],(long)(capacity-filled)]:@"Empty cannon";
    [self updateMeter];
}
- (void)drawRect:(CGRect)rect {
    CGSize size=CGSizeMake(MIN(110,self.bounds.size.width),self.bounds.size.height);if(size.width<=0||size.height<=0)return;
    if(!_bodyImage||!CGSizeEqualToSize(size,_bodySize)){
        _bodySize=size;UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithSize:size];
        _bodyImage=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){MCDrawCannon((CGRect){CGPointZero,size},self->_color?:[UIColor colorWithRed:.76 green:.8 blue:.76 alpha:1],0);}];
    }
    [_bodyImage drawAtPoint:CGPointMake((self.bounds.size.width-size.width)/2,0)];
}
- (void)consumeShot {[self showColor:_color symbol:_symbol filled:MIN(_capacity,_filled+1) capacity:_capacity];}
- (void)land {[self.layer addAnimation:_recoil forKey:@"cannon-recoil"];}
@end
