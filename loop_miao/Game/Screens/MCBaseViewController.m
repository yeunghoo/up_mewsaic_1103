#import "MCBaseViewController.h"
@implementation MCBaseViewController {
    NSLayoutConstraint *_viewportHeight;
}
- (void)prepareForNavigation {}
- (NSArray<NSDictionary *> *)catalog {return self.session.catalog;}
- (NSMutableSet<NSString *> *)completed {return self.session.completed;}
- (NSMutableArray *)moves {return self.session.moves;}
- (void)setMoves:(NSMutableArray *)value {self.session.moves=value;}
- (MCBoard *)board {return self.session.board;}
- (void)setBoard:(MCBoard *)value {self.session.board=value;}
- (NSInteger)levelIndex {return self.session.levelIndex;}
- (void)setLevelIndex:(NSInteger)value {self.session.levelIndex=value;}
- (NSInteger)chapter {return self.session.chapter;}
- (void)setChapter:(NSInteger)value {self.session.chapter=value;}
- (NSInteger)galleryPage {return self.session.galleryPage;}
- (void)setGalleryPage:(NSInteger)value {self.session.galleryPage=value;}
- (void)home {if(!self.busy)[self.router showScreen:MCScreenHome];}
- (void)levels {if(!self.busy)[self.router showScreen:MCScreenMap];}
- (void)collection {if(!self.busy)[self.router showScreen:MCScreenCollection];}
- (void)daily {if(self.busy)return;[self.session startDailyAtDate:NSDate.date reset:NO];[self game];}
- (void)settings {if(!self.busy)[self.router showScreen:MCScreenSettings];}
- (void)game {if(!self.busy)[self.router showScreen:MCScreenBattle];}
- (void)finish {if(self.session.dailyMode&&[self.session dailyRemainingAtDate:NSDate.date]<=0)return;[self.session completeCurrentLevel];[self.router showScreen:MCScreenResults];}
- (void)save {[self.session save];}
- (NSInteger)unlocked {return [self.session unlocked];}
- (void)start:(NSInteger)index moves:(NSArray *)moves {[self.session start:index moves:moves];[self game];}
- (void)continueGame {
    if(!self.catalog.count)return;[self.session resumeCampaign];[self game];
}
- (void)nextLevel {[self start:self.levelIndex+1 moves:@[]];}
- (UILabel *)label:(NSString *)text size:(CGFloat)size {
    UILabel *l=[UILabel new];l.text=text;l.numberOfLines=0;l.textColor=Ink();l.font=[UIFont systemFontOfSize:size weight:size>24?UIFontWeightHeavy:UIFontWeightSemibold];
    l.adjustsFontForContentSizeCategory=YES;l.font=[[UIFontMetrics defaultMetrics] scaledFontForFont:l.font maximumPointSize:size*1.35];
    [self.stack addArrangedSubview:l];return l;
}

- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *b=[MCDepthButton buttonWithType:UIButtonTypeCustom];
    UIButtonConfiguration *c=[UIButtonConfiguration filledButtonConfiguration];c.title=title;c.baseBackgroundColor=[UIColor colorWithRed:.06 green:.53 blue:.50 alpha:1];c.baseForegroundColor=UIColor.whiteColor;c.cornerStyle=UIButtonConfigurationCornerStyleLarge;c.contentInsets=NSDirectionalEdgeInsetsMake(10,12,10,12);b.configuration=c;
    [b.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];return b;
}

- (void)action:(NSString *)title selector:(SEL)sel { [self.stack addArrangedSubview:[self button:title action:sel]]; }

- (void)begin:(NSString *)screen {
    self.screen=screen;_viewportHeight.active=NO;_viewportHeight=nil;self.flexHeight=nil;self.flexView=nil; for(UIView *v in self.view.subviews)[v removeFromSuperview];
    self.view.backgroundColor=Paper();self.scroll=[UIScrollView new];self.scroll.scrollEnabled=NO;self.scroll.bounces=NO;self.scroll.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:self.scroll];
    self.stack=[UIStackView new];self.stack.axis=UILayoutConstraintAxisVertical;self.stack.spacing=10;self.stack.translatesAutoresizingMaskIntoConstraints=NO;[self.scroll addSubview:self.stack];
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[self.scroll.topAnchor constraintEqualToAnchor:safe.topAnchor],[self.scroll.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],[self.scroll.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],[self.scroll.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],[self.stack.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor constant:12],[self.stack.bottomAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.bottomAnchor constant:-12],[self.stack.centerXAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.centerXAnchor],[self.stack.widthAnchor constraintLessThanOrEqualToConstant:560]]];
    NSLayoutConstraint *width=[self.stack.widthAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.widthAnchor constant:-40];width.priority=999;width.active=YES;
}

- (UIStackView *)row { UIStackView *s=[UIStackView new];s.axis=UILayoutConstraintAxisHorizontal;s.spacing=8;s.distribution=UIStackViewDistributionFillEqually;[self.stack addArrangedSubview:s];return s; }

- (MCArtworkView *)artwork:(MCLevel *)level board:(MCBoard *)board height:(CGFloat)height {
    MCArtworkView *a=[MCArtworkView new];a.accessibilityIdentifier=@"puzzle-artwork";a.level=level;a.board=board;a.backgroundColor=[UIColor colorWithRed:1 green:.99 blue:.96 alpha:1];a.layer.cornerRadius=22;a.clipsToBounds=YES;a.contentMode=UIViewContentModeRedraw;
    self.flexHeight=[a.heightAnchor constraintEqualToConstant:height];self.flexHeight.active=YES;self.flexView=a;[self.stack addArrangedSubview:a];return a;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if(self.flexHeight && self.flexView && !_viewportHeight){
        // Let Auto Layout allocate the remaining safe-area height in the same pass.
        // Measuring sibling frames here can use stale sizes during first presentation.
        self.flexHeight.active=NO;
        [self.flexView setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisVertical];
        [self.flexView setContentCompressionResistancePriority:1 forAxis:UILayoutConstraintAxisVertical];
        [self.flexView.heightAnchor constraintGreaterThanOrEqualToConstant:40].active=YES;
        _viewportHeight=[self.stack.heightAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.heightAnchor constant:-24];_viewportHeight.active=YES;
    }
}

- (UIButton *)smallButton:(NSString *)symbol label:(NSString *)label action:(SEL)action {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];[b setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];b.tintColor=Ink();b.accessibilityLabel=label;[b.heightAnchor constraintEqualToConstant:44].active=YES;[b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];return b;
}

- (void)backBar:(NSString *)title {
    UIStackView *r=[self row];r.distribution=UIStackViewDistributionFill;UIButton *home=[self smallButton:@"house.fill" label:@"Home" action:@selector(home)];[home.widthAnchor constraintEqualToConstant:44].active=YES;[r addArrangedSubview:home];
    UILabel *l=[UILabel new];l.text=title;l.textAlignment=NSTextAlignmentCenter;l.font=[UIFont systemFontOfSize:18 weight:UIFontWeightHeavy];l.textColor=Ink();[r addArrangedSubview:l];
    UIButton *help=[self smallButton:@"questionmark.circle.fill" label:@"How to play" action:@selector(help)];[help.widthAnchor constraintEqualToConstant:44].active=YES;[r addArrangedSubview:help];
}

- (void)help {[self message:@"Ready, load, color!" body:@"1. Tap a colored ammo pack to load an empty cannon. The number tells you how many shots it holds.\n\n2. Cannons shoot exposed tiles of the same color. Each hit reveals new targets deeper in the picture.\n\n3. Load other empty cannons while one fires. Each cannon reloads after using all its shots. If every available cannon is waiting for hidden targets, undo and try a different color.\n\nStart with three cannons. Unlock a fourth at level 21 and a fifth at level 41. Clear the artwork to collect it. No aiming. The campaign has no timer; Daily Challenge races the clock. Undo and hints are always free."];}

- (void)message:(NSString *)title body:(NSString *)body {UIAlertController *a=[UIAlertController alertControllerWithTitle:title message:body preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:nil]];[self presentViewController:a animated:YES completion:nil];}
@end
