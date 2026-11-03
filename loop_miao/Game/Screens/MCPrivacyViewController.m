#import "MCPrivacyViewController.h"
#import "MCBaseViewController.h"

@implementation MCPrivacyViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Privacy Policy";
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    self.view.backgroundColor = Paper();
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    UITextView *text = [UITextView new];
    text.accessibilityIdentifier = @"privacy-policy";
    text.editable = NO;
    text.dataDetectorTypes = UIDataDetectorTypeNone;
    text.backgroundColor = Paper();
    text.textColor = Ink();
    text.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    text.adjustsFontForContentSizeCategory = YES;
    text.textContainerInset = UIEdgeInsetsMake(20, 20, 28, 20);
    NSURL *url = [NSBundle.mainBundle URLForResource:@"PrivacyPolicy" withExtension:@"txt"];
    text.text = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    text.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:text];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [text.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [text.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [text.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [text.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor]
    ]];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
@end
