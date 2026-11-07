#import "MCAdNotice.h"

@implementation MCAdNotice
+ (void)showText:(NSString *)text inView:(UIView *)view success:(BOOL)success {
    for (UIView *existing in view.subviews.copy) {
        if ([existing.accessibilityIdentifier isEqualToString:@"ad-notice"]) [existing removeFromSuperview];
    }
    UIView *pill = [UIView new]; pill.translatesAutoresizingMaskIntoConstraints = NO;
    pill.accessibilityIdentifier = @"ad-notice"; pill.userInteractionEnabled = NO;
    pill.backgroundColor = success ? [UIColor colorWithRed:.06 green:.39 blue:.34 alpha:.97] : [UIColor colorWithRed:.18 green:.24 blue:.29 alpha:.97];
    pill.layer.cornerRadius = 15; pill.layer.shadowOpacity = .15; pill.layer.shadowRadius = 6; pill.layer.shadowOffset = CGSizeMake(0, 3);
    UILabel *label = [UILabel new]; label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text; label.textColor = UIColor.whiteColor; label.numberOfLines = 2; label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [pill addSubview:label]; [view addSubview:pill];
    UILayoutGuide *safe = view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [pill.topAnchor constraintEqualToAnchor:safe.topAnchor constant:6],
        [pill.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [pill.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:12],
        [pill.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-12],
        [pill.widthAnchor constraintLessThanOrEqualToConstant:380],
        [label.topAnchor constraintEqualToAnchor:pill.topAnchor constant:10],
        [label.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-10],
        [label.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:16],
        [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-16]]];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, text);
    pill.alpha = 0;
    [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled()?0:.18 animations:^{pill.alpha=1;}];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:.2 animations:^{pill.alpha=0;} completion:^(BOOL finished){[pill removeFromSuperview];}];
    });
}
@end
