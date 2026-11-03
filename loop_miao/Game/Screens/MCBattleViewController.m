#import "MCBattleViewController.h"
#import "MCAmmoStackView.h"
#import "MCAmmoTrayView.h"
#import "MCVolleyTimeline.h"
#import "MCShotEffects.h"
#import "MCSoundPlayer.h"

@interface MCBattleViewController ()
@property(nonatomic,strong) MCArtworkView *art;
@property(nonatomic,strong) UIStackView *slotsRow;
@property(nonatomic,strong) MCAmmoTrayView *ammoTray;
@property(nonatomic,strong) MCAmmoStackView *preview;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIButton *hintButton;
@property(nonatomic,strong) MCVolleyTimeline *timeline;
@property(nonatomic,strong) MCShotEffects *effects;
@property(nonatomic,strong) CADisplayLink *displayLink;
@property(nonatomic) CFTimeInterval lastFrame;
@property(nonatomic,strong) UILabel *countdown;
@property(nonatomic,strong) NSTimer *deadlineTimer;
@property(nonatomic) BOOL timeoutShown;
@property(nonatomic) NSTimeInterval lastSnapshot;
@property(nonatomic,strong) UIButton *undoButton;
@end

@implementation MCBattleViewController
- (void)viewDidLoad {
    [super viewDidLoad];self.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;
    self.timeline=[[MCVolleyTimeline alloc]initWithBoard:self.board];
    if(self.session.dailyMode&&self.session.dailyVisualState)[self.timeline restoreSnapshot:self.session.dailyVisualState];
    [self renderScreen];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pauseVolley) name:UIApplicationWillResignActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeVolley) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)prepareForNavigation {[self persistVisualState];[self.deadlineTimer invalidate];self.deadlineTimer=nil;[self stopVolley];}
- (void)dealloc {[NSNotificationCenter.defaultCenter removeObserver:self];}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(self.session.dailyMode){
        [self checkDeadline];if(self.timeoutShown)return;
        if(!self.deadlineTimer)self.deadlineTimer=[NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(checkDeadline) userInfo:nil repeats:YES];
    }
    if(self.timeline.running)[self startDisplayLink];
    if(self.board.isWin&&!self.timeline.running){[self finish];return;}
    if(self.board.isDeadlock&&!self.timeline.running){[self blocked];return;}
    if(!self.session.dailyMode&&![NSUserDefaults.standardUserDefaults boolForKey:@"atelier.taught"]){[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"atelier.taught"];[self help];}
}
- (void)viewWillDisappear:(BOOL)animated {[super viewWillDisappear:animated];}
- (void)renderScreen {
    [self begin:@"game"];self.stack.spacing=4;
    UIStackView *nav=[self row];nav.distribution=UIStackViewDistributionFill;UIButton *back=[self smallButton:self.session.dailyMode?@"house.fill":@"map.fill" label:self.session.dailyMode?@"Home":@"Adventure map" action:self.session.dailyMode?@selector(home):@selector(levels)];[back.widthAnchor constraintEqualToConstant:44].active=YES;[nav addArrangedSubview:back];
    UILabel *level=[UILabel new];level.text=self.session.dailyMode?@"DAILY CHALLENGE":[NSString stringWithFormat:@"LEVEL %ld",(long)self.levelIndex+1];level.textAlignment=NSTextAlignmentCenter;level.font=[UIFont systemFontOfSize:18 weight:UIFontWeightHeavy];level.textColor=Ink();[nav addArrangedSubview:level];
    UIButton *help=[self smallButton:@"questionmark.circle.fill" label:@"How to play" action:@selector(help)];[help.widthAnchor constraintEqualToConstant:44].active=YES;[nav addArrangedSubview:help];
    UILabel *name=[self label:self.session.currentLevelInfo[@"title"] size:24];name.textAlignment=NSTextAlignmentCenter;
    if(self.session.dailyMode){self.countdown=[self label:@"" size:20];self.countdown.textAlignment=NSTextAlignmentCenter;self.countdown.font=[UIFont monospacedDigitSystemFontOfSize:20 weight:UIFontWeightHeavy];self.countdown.accessibilityIdentifier=@"daily-countdown";}
    self.status=[self label:@"" size:13];self.status.numberOfLines=1;
    [self.status.heightAnchor constraintEqualToConstant:ceil(self.status.font.lineHeight)].active=YES;
    self.art=[self artwork:self.board.level board:nil height:300];self.art.displayedColors=self.timeline.colors;self.art.accessibilityIdentifier=@"puzzle-artwork";
    self.art.backgroundColor=[UIColor colorWithRed:.82 green:.89 blue:.96 alpha:1];
    [self label:[NSString stringWithFormat:@"%ld CANNONS  •  Load while others fire",(long)self.board.level.slotCount] size:10];
    self.slotsRow=[self row];
    for(NSInteger i=0;i<self.board.level.slotCount;i++){
        MCCannonView *c=[MCCannonView new];[c.heightAnchor constraintEqualToConstant:68].active=YES;
        id displayed=self.timeline.displaySlots[i];
        if(displayed!=NSNull.null)[c showColor:[MCPalette colorForKey:displayed[@"color"]] symbol:displayed[@"color"] filled:[displayed[@"filled"] integerValue] capacity:[displayed[@"capacity"] integerValue]];
        c.isAccessibilityElement=YES;c.accessibilityIdentifier=[NSString stringWithFormat:@"cannon-%ld",(long)i];[self.slotsRow addArrangedSubview:c];
    }
    [self label:@"CHOOSE A COLOR" size:10];
    self.ammoTray=[MCAmmoTrayView new];self.ammoTray.target=self;self.ammoTray.action=@selector(pick:);
    [self.ammoTray.heightAnchor constraintEqualToConstant:54].active=YES;[self.stack addArrangedSubview:self.ammoTray];
    self.preview=[MCAmmoStackView new];[self.preview.heightAnchor constraintEqualToConstant:44].active=YES;[self.stack addArrangedSubview:self.preview];
    UIStackView *actions=[self row];self.undoButton=[self button:@"Undo" action:@selector(undo)];[actions addArrangedSubview:self.undoButton];
    self.hintButton=[self button:@"Hint" action:@selector(hint)];[actions addArrangedSubview:self.hintButton];[actions addArrangedSubview:[self button:@"Restart" action:@selector(restart)]];
    self.effects=[[MCShotEffects alloc]initWithHost:self.view artwork:self.art cannons:(NSArray *)self.slotsRow.arrangedSubviews];
    [self refreshQueue];[self refreshControls];
}
- (NSInteger)availableSlot {
    NSArray *slots=self.board.slots;
    for(NSInteger i=0;i<slots.count;i++)if(slots[i]==NSNull.null&&![self.timeline isSlotAnimating:i])return i;
    return NSNotFound;
}
- (void)refreshQueue {
    NSArray *indexes=self.board.selectableQueueIndexes;NSMutableArray *available=[NSMutableArray new];
    for(NSNumber *index in indexes)[available addObject:self.board.level.baskets[index.integerValue]];
    [self.ammoTray showPacks:available indexes:indexes];
    NSArray *visible=self.board.visibleQueueIndexes;NSMutableArray *packs=[NSMutableArray new];
    for(NSUInteger i=self.board.selectableQueueIndexes.count;i<visible.count;i++)[packs addObject:self.board.level.baskets[[visible[i] integerValue]]];
    self.preview.packs=packs;
}
- (void)refreshControls {
    self.status.text=[NSString stringWithFormat:@"%lu tiles left   •   %lu loads",(unsigned long)self.timeline.colors.count,(unsigned long)self.moves.count];
    BOOL available=[self availableSlot]!=NSNotFound;
    [self.ammoTray setLoadingEnabled:available&&!self.timeoutShown];
    self.hintButton.enabled=!self.timeline.running&&!self.timeoutShown;self.undoButton.enabled=!self.timeoutShown;
    NSArray *slots=self.board.slots;
    for(NSInteger i=0;i<slots.count;i++){
        MCCannonView *view=(MCCannonView *)self.slotsRow.arrangedSubviews[i];
        if([self.timeline isSlotAnimating:i]){view.accessibilityValue=@"Firing";continue;}
        if(slots[i]==NSNull.null){[view showColor:[UIColor colorWithRed:.63 green:.76 blue:.83 alpha:1] symbol:@"" filled:0 capacity:0];view.accessibilityValue=@"Ready";}
        else {MCBasket *b=slots[i];[view showColor:[MCPalette colorForKey:b.colorKey] symbol:b.colorKey filled:b.filled capacity:b.capacity];view.accessibilityValue=@"Waiting for matching tiles";}
    }
}
- (void)pick:(UIButton *)sender {
    if(self.session.dailyMode&&[self checkExpired])return;
    NSInteger slot=[self availableSlot];if(slot==NSNotFound)return;
    MCMove *move=[self.board playBasketAtQueueIndex:sender.tag slotIndex:slot];if(!move)return;
    [self.moves addObject:@{@"pick":@(sender.tag),@"slot":@(slot)}];
    MCCannonView *c=(MCCannonView *)self.slotsRow.arrangedSubviews[slot];[c showColor:[MCPalette colorForKey:move.colorKey] symbol:move.colorKey filled:0 capacity:move.capacity];
    [[MCSoundPlayer shared]play:@"load"];
    [self.timeline enqueueMove:move];if(self.session.dailyMode)[self persistVisualState];else [self save];[self refreshQueue];[self refreshControls];
    [self startDisplayLink];
    if(!self.timeline.running&&self.board.isDeadlock)[self blocked];
}
- (void)startDisplayLink {
    if(!self.displayLink&&self.timeline.running&&!self.timeoutShown){self.lastFrame=0;self.displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(frame:)];self.displayLink.preferredFramesPerSecond=60;[self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];}
}
- (void)frame:(CADisplayLink *)link {
    if(self.session.dailyMode&&[self checkExpired])return;
    NSTimeInterval delta=self.lastFrame?MIN(.05,link.timestamp-self.lastFrame):1.0/60;self.lastFrame=link.timestamp;
    [self.timeline advance:delta];[self.effects renderTimeline:self.timeline];
    if(self.timeline.impacts.count){
        CGFloat cell=MIN((self.art.bounds.size.width-24)/self.board.level.cols,(self.art.bounds.size.height-24)/self.board.level.rows);
        for(MCVolleyShot *hit in self.timeline.impacts){CGFloat x=(self.art.bounds.size.width-cell*self.board.level.cols)/2+hit.index%self.board.level.cols*cell,y=(self.art.bounds.size.height-cell*self.board.level.rows)/2+hit.index/self.board.level.cols*cell;[self.art setNeedsDisplayInRect:CGRectInset(CGRectMake(x,y,cell,cell),-1,-1)];}
        [self refreshControls];
        if(NSDate.timeIntervalSinceReferenceDate-self.lastSnapshot>1)[self persistVisualState];
    }
    if(!self.timeline.running){[self.displayLink invalidate];self.displayLink=nil;[self refreshControls];if(self.board.isWin)[self finish];else if(self.board.isDeadlock)[self blocked];}
}
- (void)pauseVolley {[self persistVisualState];self.displayLink.paused=YES;self.lastFrame=0;}
- (void)resumeVolley {self.lastFrame=0;if(self.session.dailyMode&&[self checkExpired])return;self.displayLink.paused=NO;}
- (void)stopVolley {[self.displayLink invalidate];self.displayLink=nil;[self.effects clear];[[MCSoundPlayer shared]stop];}

- (void)persistVisualState {
    if(!self.session.dailyMode||!self.timeline||self.timeoutShown)return;
    self.session.dailyVisualState=[self.timeline snapshot];self.lastSnapshot=NSDate.timeIntervalSinceReferenceDate;[self save];
}
- (void)checkDeadline {
    if(!self.session.dailyMode)return;
    NSInteger remaining=(NSInteger)ceil([self.session dailyRemainingAtDate:NSDate.date]);
    self.countdown.text=[NSString stringWithFormat:@"◷  %02ld:%02ld",(long)remaining/60,(long)remaining%60];
    self.countdown.textColor=remaining<=20?[UIColor colorWithRed:.9 green:.18 blue:.24 alpha:1]:Ink();
    [self checkExpired];
}
- (BOOL)checkExpired {
    if(!self.session.dailyMode||[self.session dailyRemainingAtDate:NSDate.date]>0)return NO;
    if(self.timeoutShown)return YES;
    self.timeoutShown=YES;[self.session failDaily];[self.deadlineTimer invalidate];self.deadlineTimer=nil;[self stopVolley];[self refreshControls];self.countdown.text=@"◷  00:00";
    if(self.presentedViewController)[self dismissViewControllerAnimated:NO completion:^{[self showTimeout];}];else [self showTimeout];
    return YES;
}
- (void)showTimeout {
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Time's up!" message:@"The daily challenge clock has run out. Try a different color order and go again." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Try again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a){[self restartCurrent];}]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Back to home" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a){[self home];}]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)restartCurrent {
    [self stopVolley];[self.deadlineTimer invalidate];self.deadlineTimer=nil;
    if(self.session.dailyMode){self.timeline=nil;[self.session startDailyAtDate:NSDate.date reset:YES];[self game];}
    else [self start:self.levelIndex moves:@[]];
}

- (void)undo {
    if(self.timeoutShown||!self.moves.count)return;[self stopVolley];NSMutableArray *a=[self.moves mutableCopy];[a removeLastObject];
    if(self.session.dailyMode){self.session.dailyVisualState=nil;[self.session restoreDailyMoves:a];self.timeline=nil;[self game];}
    else [self start:self.levelIndex moves:a];
}

- (void)restart {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Start this puzzle again?" message:@"Your collected keepsakes stay safe." preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"Keep playing" style:UIAlertActionStyleCancel handler:nil]];[a addAction:[UIAlertAction actionWithTitle:@"Restart" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x){[self restartCurrent];}]];[self presentViewController:a animated:YES completion:nil];
}

- (void)hint {
    if(self.timeline.running)return;
    // Validate the full remaining queue on an independent board; no exponential search on UI thread.
    MCBoard *test=[[MCBoard alloc]initWithLevel:self.board.level];for(id record in self.moves)[MCGameSession replayMove:record onBoard:test];
    NSInteger pick=test.selectableQueueIndexes.firstObject.integerValue;
    while(!test.isWin&&!test.isDeadlock&&test.selectableQueueIndexes.count)[test playBasketAtQueueIndex:test.selectableQueueIndexes.firstObject.integerValue];
    if(test.isWin){for(UIButton *b in self.ammoTray.buttons)if(b.tag==pick){b.layer.borderColor=Ink().CGColor;b.layer.borderWidth=4;}[self message:@"Load the outlined ammo pack" body:@"It starts a verified route from your current board. Watch which colors the outer tiles reveal."];}
    else [self message:@"Make a little room" body:@"Look for an exposed color that can use up a full ammo pack. No verified hint is available here; Undo lets you reconsider your last choice."];
}

- (void)blocked {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Your cannons are waiting" message:@"All available cannons are waiting for hidden colors. Undo a load and try a different color." preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"Undo last move" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x){[self undo];}]];[a addAction:[UIAlertAction actionWithTitle:@"Look at the board" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];
}
@end
