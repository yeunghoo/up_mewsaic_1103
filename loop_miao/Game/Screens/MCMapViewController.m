#import "MCMapViewController.h"
@implementation MCMapViewController
- (void)viewDidLoad {[super viewDidLoad];self.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;[self renderScreen];}
- (void)renderScreen {
    if(self.busy)return;[self begin:@"levels"];[self backBar:@"Adventure map"];
    [self label:self.catalog[self.chapter*20][@"chapter"] size:28];
    NSInteger earned=0;NSMutableSet *done=[NSMutableSet new];for(NSInteger i=0;i<self.catalog.count;i++)if([self.completed containsObject:self.catalog[i][@"id"]]){[done addObject:@(i)];if(i/20==self.chapter)earned++;}
    [self label:[NSString stringWithFormat:@"CHAPTER %02ld   •   ★ %ld / 20 keepsakes",(long)self.chapter+1,(long)earned] size:13];
    MCMapView *map=[MCMapView new];map.firstLevel=self.chapter*20;map.unlockedLevel=[self unlocked];map.finishedLevels=done;map.target=self;map.action=@selector(selectLevel:);[map build];[self.stack addArrangedSubview:map];self.flexView=map;self.flexHeight=[map.heightAnchor constraintEqualToConstant:350];self.flexHeight.active=YES;
    UIStackView *nav=[self row];UIButton *prev=[self button:@"‹ Previous" action:@selector(prevChapter)];prev.enabled=self.chapter>0;[nav addArrangedSubview:prev];UIButton *next=[self button:@"Next ›" action:@selector(nextChapter)];next.enabled=self.chapter<9;[nav addArrangedSubview:next];
}

- (void)prevChapter {self.chapter=MAX(0,self.chapter-1);[self renderScreen];}

- (void)nextChapter {self.chapter=MIN(9,self.chapter+1);[self renderScreen];}

- (void)selectLevel:(UIButton *)sender {[self start:sender.tag moves:@[]];}
@end
