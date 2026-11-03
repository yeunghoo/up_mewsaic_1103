#import "MCAmmoTrayView.h"
#import "MCDepthButton.h"
#import "MCPalette.h"
@implementation MCAmmoTrayView
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        NSMutableArray *buttons=[NSMutableArray new];
        for(int i=0;i<5;i++){
            MCDepthButton *button=[MCDepthButton buttonWithType:UIButtonTypeCustom];button.basketStyle=YES;button.tag=NSNotFound;button.alpha=0;
            [button addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];[self addSubview:button];[buttons addObject:button];
        }_buttons=buttons;
    }return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];CGFloat width=MIN(66,(self.bounds.size.width-32)/5),origin=(self.bounds.size.width-width*5-32)/2;
    for(int i=0;i<5;i++)self.buttons[i].frame=CGRectMake(origin+i*(width+8),0,width,self.bounds.size.height);
}
- (void)tapped:(UIButton *)button {[UIApplication.sharedApplication sendAction:self.action to:self.target from:button forEvent:nil];}
- (void)showPacks:(NSArray *)packs indexes:(NSArray *)indexes {
    for(NSInteger i=0;i<self.buttons.count;i++){
        MCDepthButton *b=self.buttons[i];BOOL visible=i<indexes.count;
        b.alpha=visible?1:0;b.accessibilityElementsHidden=!visible;b.userInteractionEnabled=visible;
        if(!visible){b.tag=NSNotFound;b.accessibilityIdentifier=nil;continue;}
        NSInteger index=[indexes[i] integerValue];if(b.tag==index)continue;
        b.tag=index;b.layer.borderWidth=0;
        MCBasketSpec *pack=packs[i];UIButtonConfiguration *c=[UIButtonConfiguration filledButtonConfiguration];
        c.title=[NSString stringWithFormat:@"%ld",(long)pack.capacity];c.baseBackgroundColor=[MCPalette colorForKey:pack.colorKey];c.baseForegroundColor=[MCPalette isLightColorForKey:pack.colorKey]?[UIColor colorWithWhite:.12 alpha:1]:UIColor.whiteColor;
        c.contentInsets=NSDirectionalEdgeInsetsMake(8,2,8,2);c.titleTextAttributesTransformer=^NSDictionary *(NSDictionary *a){NSMutableDictionary *d=[a mutableCopy];d[NSFontAttributeName]=[UIFont monospacedDigitSystemFontOfSize:23 weight:UIFontWeightHeavy];return d;};b.configuration=c;
        b.accessibilityIdentifier=[NSString stringWithFormat:@"basket-%ld",(long)index];b.accessibilityLabel=[NSString stringWithFormat:@"%@ ammo, %ld shots",[MCPalette nameForKey:pack.colorKey],(long)pack.capacity];
    }
}
- (void)setLoadingEnabled:(BOOL)enabled {for(UIButton *b in self.buttons)if(b.enabled!=enabled)b.enabled=enabled;}
@end
