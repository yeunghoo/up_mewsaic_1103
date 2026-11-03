#import "MCHomeViewController.h"
#import "MCHomeShowcaseView.h"
@implementation MCHomeViewController
- (void)viewDidLoad {[super viewDidLoad];self.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;[self renderScreen];}
- (void)renderScreen {
    if(self.busy)return;[self begin:@"home"];
    UIStackView *top=[self row];[top addArrangedSubview:[self smallButton:@"square.grid.2x2.fill" label:@"Collection" action:@selector(collection)]];
    UILabel *badge=[UILabel new];badge.text=[NSString stringWithFormat:@"★  %lu / 200",(unsigned long)self.completed.count];badge.textAlignment=NSTextAlignmentCenter;badge.font=[UIFont systemFontOfSize:16 weight:UIFontWeightHeavy];badge.textColor=Ink();[top addArrangedSubview:badge];
    [top addArrangedSubview:[self smallButton:@"gearshape.fill" label:@"Settings" action:@selector(settings)]];
    UILabel *title=[self label:@"Mewsaic Nook" size:36];title.textAlignment=NSTextAlignmentCenter;title.layer.shadowColor=UIColor.whiteColor.CGColor;title.layer.shadowOffset=CGSizeMake(0,3);title.layer.shadowOpacity=1;title.layer.shadowRadius=0;
    UILabel *sub=[self label:@"Tiny cannons. Big colorful adventures." size:15];sub.textAlignment=NSTextAlignmentCenter;
    NSInteger next=[self unlocked];NSDictionary *info=self.catalog[next];
    MCHomeShowcaseView *hero=[[MCHomeShowcaseView alloc]initWithLevel:[MCLevel levelWithDictionary:info] title:info[@"title"] completed:self.completed.count];
    self.flexHeight=[hero.heightAnchor constraintEqualToConstant:300];self.flexHeight.active=YES;self.flexView=hero;[self.stack addArrangedSubview:hero];
    UIButton *play=[self button:[NSString stringWithFormat:@"PLAY  •  LEVEL %ld",(long)[self unlocked]+1] action:@selector(continueGame)];play.accessibilityIdentifier=@"play";UIButtonConfiguration *c=play.configuration;c.baseBackgroundColor=[UIColor colorWithRed:1 green:.48 blue:.28 alpha:1];c.titleTextAttributesTransformer=^NSDictionary *(NSDictionary *a){return @{NSFontAttributeName:[UIFont systemFontOfSize:22 weight:UIFontWeightHeavy]};};play.configuration=c;[play.heightAnchor constraintEqualToConstant:60].active=YES;[self.stack addArrangedSubview:play];
    UIButton *daily=[self button:[self.session.dailyStore isCompletedOnDate:NSDate.date]?@"DAILY CHALLENGE  ✓":@"DAILY CHALLENGE  •  EXPERT" action:@selector(daily)];daily.accessibilityIdentifier=@"daily";
    UIButtonConfiguration *dc=daily.configuration;dc.baseBackgroundColor=[UIColor colorWithRed:.56 green:.25 blue:.76 alpha:1];dc.image=[UIImage systemImageNamed:@"timer"];dc.imagePadding=8;daily.configuration=dc;[daily.heightAnchor constraintEqualToConstant:52].active=YES;[self.stack addArrangedSubview:daily];
    UIButton *map=[UIButton buttonWithType:UIButtonTypeSystem];[map setTitle:@"Explore the adventure map  →" forState:UIControlStateNormal];map.titleLabel.font=[UIFont systemFontOfSize:16 weight:UIFontWeightBold];map.tintColor=Ink();[map.heightAnchor constraintEqualToConstant:44].active=YES;[map addTarget:self action:@selector(levels) forControlEvents:UIControlEventTouchUpInside];map.accessibilityIdentifier=@"map";[self.stack addArrangedSubview:map];
}
@end
