#import "MCGameViewController.h"
#import "MCGameSession.h"
#import "MCHomeViewController.h"
#import "MCMapViewController.h"
#import "MCBattleViewController.h"
#import "MCResultsViewController.h"
#import "MCCollectionViewController.h"
#import "MCSettingsViewController.h"
#import "MCDebugPreview.h"
@interface MCGameViewController ()
@property(nonatomic,strong,readwrite) MCGameSession *session;
@property(nonatomic,strong) MCBaseViewController *activeScreen;
@end
@implementation MCGameViewController
- (void)viewDidLoad {[super viewDidLoad];self.session=[MCGameSession new];
#if DEBUG
    NSInteger preview=[MCDebugPreview configure:self.session];if(preview>=0){[self showScreen:preview];return;}
    if([NSUserDefaults.standardUserDefaults objectForKey:@"MCPreviewLevel"]){NSInteger index=[NSUserDefaults.standardUserDefaults integerForKey:@"MCPreviewLevel"];if(index>=0&&index<self.session.catalog.count){[self.session start:index moves:@[]];
        if([NSUserDefaults.standardUserDefaults boolForKey:@"MCPreviewWin"]){
            while(!self.session.board.isWin&&!self.session.board.isDeadlock&&self.session.board.selectableQueueIndexes.count){NSNumber *pick=self.session.board.selectableQueueIndexes.firstObject;[self.session.board playBasketAtQueueIndex:pick.integerValue];[self.session.moves addObject:pick];}
            [self.session completeCurrentLevel];[self showScreen:MCScreenResults];return;
        }
        [self showScreen:MCScreenBattle];return;}}
#endif
    [self showScreen:MCScreenHome];}
- (void)showScreen:(MCScreen)screen {
    NSArray *classes=@[MCHomeViewController.class, MCMapViewController.class, MCBattleViewController.class, MCResultsViewController.class, MCCollectionViewController.class, MCSettingsViewController.class];
    MCBaseViewController *next=[[classes[screen] alloc]init];next.session=self.session;next.router=self;
    [self.activeScreen prepareForNavigation];
    [self.activeScreen willMoveToParentViewController:nil];[self.activeScreen.view removeFromSuperview];[self.activeScreen removeFromParentViewController];
    self.activeScreen=next;[self addChildViewController:next];next.view.frame=self.view.bounds;next.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[self.view addSubview:next.view];[next didMoveToParentViewController:self];
}
@end
