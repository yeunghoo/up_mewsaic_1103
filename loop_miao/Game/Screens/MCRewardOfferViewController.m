#import "MCRewardOfferViewController.h"
#import "../Ads/MCAdManager.h"
#import "MCDepthButton.h"

@implementation MCRewardOfferViewController {
    MCAdManager *_ads;
    NSInteger _seconds;
    UIView *_bannerContainer;
    BOOL _closing;
}
- (instancetype)initWithAdManager:(MCAdManager *)ads seconds:(NSInteger)seconds {
    if ((self=[super init])) {
        _ads=ads; _seconds=seconds;
        self.modalPresentationStyle=UIModalPresentationOverFullScreen;
        self.modalInPresentation=YES;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;
    self.view.backgroundColor=[UIColor colorWithWhite:0 alpha:.48]; self.view.accessibilityViewIsModal=YES;
    UIView *card=[UIView new]; card.translatesAutoresizingMaskIntoConstraints=NO; card.accessibilityIdentifier=@"daily-reward-offer";
    card.backgroundColor=[UIColor colorWithRed:1 green:.98 blue:.92 alpha:1]; card.layer.cornerRadius=26;
    card.layer.borderWidth=2; card.layer.borderColor=[UIColor colorWithRed:.81 green:.88 blue:.79 alpha:1].CGColor;
    card.layer.shadowColor=UIColor.blackColor.CGColor; card.layer.shadowOpacity=.24; card.layer.shadowRadius=16; card.layer.shadowOffset=CGSizeMake(0,8);
    [self.view addSubview:card];
    UIStackView *content=[UIStackView new]; content.axis=UILayoutConstraintAxisVertical; content.spacing=14; content.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:content];
    UILabel *title=[UILabel new]; title.text=@"A little more time?"; title.textAlignment=NSTextAlignmentCenter; title.font=[UIFont systemFontOfSize:24 weight:UIFontWeightHeavy]; title.textColor=[UIColor colorWithRed:.10 green:.25 blue:.26 alpha:1]; title.numberOfLines=2; [content addArrangedSubview:title];
    UILabel *body=[UILabel new]; body.text=[NSString stringWithFormat:@"Watch a video to add %ld seconds to this challenge.\nYour timer pauses while the offer is open and the video plays.",(long)_seconds]; body.textAlignment=NSTextAlignmentCenter; body.font=[UIFont systemFontOfSize:15 weight:UIFontWeightMedium]; body.textColor=[UIColor colorWithRed:.26 green:.36 blue:.37 alpha:1]; body.numberOfLines=0; [content addArrangedSubview:body];
    UIButton *watch=[MCDepthButton buttonWithType:UIButtonTypeCustom];
    UIButtonConfiguration *configuration=[UIButtonConfiguration filledButtonConfiguration]; configuration.title=@"Watch Video"; configuration.image=[UIImage systemImageNamed:@"play.rectangle.fill"]; configuration.imagePadding=8; configuration.baseBackgroundColor=[UIColor colorWithRed:.06 green:.53 blue:.50 alpha:1]; configuration.baseForegroundColor=UIColor.whiteColor; configuration.cornerStyle=UIButtonConfigurationCornerStyleLarge; watch.configuration=configuration;
    watch.accessibilityIdentifier=@"watch-reward-video"; [watch.heightAnchor constraintEqualToConstant:50].active=YES; [watch addTarget:self action:@selector(watch) forControlEvents:UIControlEventTouchUpInside]; [content addArrangedSubview:watch];
    UIButton *cancel=[UIButton buttonWithType:UIButtonTypeSystem]; [cancel setTitle:@"Not Now" forState:UIControlStateNormal]; cancel.tintColor=title.textColor; cancel.titleLabel.font=[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]; cancel.accessibilityIdentifier=@"cancel-reward-video"; [cancel.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES; [cancel addTarget:self action:@selector(closeWithoutWatching) forControlEvents:UIControlEventTouchUpInside]; [content addArrangedSubview:cancel];
    _bannerContainer=[UIView new]; _bannerContainer.translatesAutoresizingMaskIntoConstraints=NO; _bannerContainer.accessibilityIdentifier=@"reward-banner-container";
    [self.view addSubview:_bannerContainer]; // Same parent and presentation level as card.
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    NSLayoutConstraint *width=[card.widthAnchor constraintEqualToConstant:360]; width.priority=UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        width,[card.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor constant:-32],
        [card.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:safe.centerYAnchor constant:-32],
        [card.topAnchor constraintGreaterThanOrEqualToAnchor:safe.topAnchor constant:12],
        [card.bottomAnchor constraintLessThanOrEqualToAnchor:_bannerContainer.topAnchor constant:-20],
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
        [_bannerContainer.widthAnchor constraintEqualToConstant:320],[_bannerContainer.heightAnchor constraintEqualToConstant:50],
        [_bannerContainer.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [_bannerContainer.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8]]];
    self.view.alpha=0;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_closing) return;
    [self.view layoutIfNeeded];
    [_ads showBannerInContainer:_bannerContainer];
    [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled()?0:.18 animations:^{self.view.alpha=1;}];
}
- (void)watch { [self choose:YES]; }
- (void)closeWithoutWatching { [self choose:NO]; }
- (void)choose:(BOOL)watch {
    if (_closing) return;
    _closing=YES; self.view.userInteractionEnabled=NO;
    [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled()?0:.15 animations:^{self.view.alpha=0;} completion:^(BOOL finished){
        [self->_ads hideBanner];
        void (^decision)(BOOL)=self.decision; self.decision=nil;
        [self dismissViewControllerAnimated:NO completion:^{if(decision)decision(watch);}];
    }];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // Full-screen content opened by the banner must not remove the offer itself.
    if (self.isBeingDismissed || !self.presentingViewController) [_ads hideBanner];
}
@end
