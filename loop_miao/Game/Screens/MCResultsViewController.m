#import "MCResultsViewController.h"
#import "MCSoundPlayer.h"
@implementation MCResultsViewController
- (void)viewDidLoad {[super viewDidLoad];self.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;[self renderScreen];[[MCSoundPlayer shared] play:@"win"];}
- (void)renderScreen {
    [self begin:@"win"];
    UILabel *stars=[self label:@"★   ★   ★" size:32];stars.textColor=[UIColor colorWithRed:.95 green:.64 blue:.13 alpha:1];stars.textAlignment=NSTextAlignmentCenter;
    UILabel *title=[self label:@"Colorfully cleared!" size:31];title.textAlignment=NSTextAlignmentCenter;
    UILabel *name=[self label:self.session.currentLevelInfo[@"title"] size:15];name.textAlignment=NSTextAlignmentCenter;
    [self artwork:self.board.level board:nil height:280];
    [self label:[NSString stringWithFormat:@"✓ %@     •     %lu loads",self.session.dailyMode?@"Challenge cleared":@"Keepsake collected",(unsigned long)self.moves.count] size:14];
    if(self.session.dailyMode){
        NSInteger remaining=(NSInteger)floor([self.session dailyRemainingAtDate:NSDate.date]);
        [self label:[NSString stringWithFormat:@"DAILY MASTERED  •  %ld seconds to spare",(long)remaining] size:17];
        [self label:@"Today's badge is yours. Come back tomorrow for the next challenge." size:14];
        [self action:@"Back to home" selector:@selector(home)];return;
    }
    NSInteger earned=0;for(NSInteger i=self.levelIndex/20*20;i<self.levelIndex/20*20+20;i++)if([self.completed containsObject:self.catalog[i][@"id"]])earned++;
    UIProgressView *progress=[[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];progress.progress=earned/20.0;progress.progressTintColor=[UIColor colorWithRed:.1 green:.66 blue:.5 alpha:1];[self.stack addArrangedSubview:progress];
    [self label:[NSString stringWithFormat:@"%@  •  %ld / 20\n%@",self.catalog[self.levelIndex][@"chapter"],(long)earned,self.levelIndex==199?@"All adventures complete!":@"Next adventure unlocked!"] size:14];
    if(self.levelIndex<199)[self action:@"Next adventure  →" selector:@selector(nextLevel)];else [self action:@"Visit collection" selector:@selector(collection)];
    [self.stack addArrangedSubview:[self smallButton:@"map.fill" label:@"Adventure map" action:@selector(levels)]];
}
@end
