#import "MCSettingsViewController.h"
#import "MCSoundPlayer.h"
#import "MCPrivacyViewController.h"
@implementation MCSettingsViewController
- (void)viewDidLoad {[super viewDidLoad];self.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;[self renderScreen];}
- (void)renderScreen {
    [self begin:@"settings"];[self backBar:@"Settings"];[self label:@"Make yourself at home" size:25];
    [self action:[NSUserDefaults.standardUserDefaults boolForKey:@"atelier.haptics"]?@"Haptic feedback: On":@"Haptic feedback: Off" selector:@selector(toggleHaptics)];
    [self action:[NSUserDefaults.standardUserDefaults boolForKey:@"atelier.sound"]?@"Sound effects: On":@"Sound effects: Off" selector:@selector(toggleSound)];
    [self label:@"Sound follows your device’s silent mode. Animations follow Reduce Motion." size:14];
    [self label:@"Your progress belongs here" size:20];[self label:@"Progress is saved on this device. No account, ads, analytics, or purchases. Deleting the app removes its local progress." size:15];
    NSString *version=[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [self label:[NSString stringWithFormat:@"Mewsaic Nook · Version %@\nOriginal procedural artwork and a cozy place to think.",version] size:14];
    UIButton *privacy=[UIButton buttonWithType:UIButtonTypeSystem];
    [privacy setTitle:@"Privacy Policy" forState:UIControlStateNormal];
    privacy.tintColor=Ink();privacy.accessibilityIdentifier=@"privacy";
    [privacy.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;
    [privacy addTarget:self action:@selector(showPrivacy) forControlEvents:UIControlEventTouchUpInside];
    [self.stack addArrangedSubview:privacy];
}
- (void)showPrivacy {
    UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:[MCPrivacyViewController new]];
    navigation.modalPresentationStyle=UIModalPresentationFullScreen;
    [self presentViewController:navigation animated:YES completion:nil];
}

- (void)toggleHaptics {[NSUserDefaults.standardUserDefaults setBool:![NSUserDefaults.standardUserDefaults boolForKey:@"atelier.haptics"] forKey:@"atelier.haptics"];[self renderScreen];}
- (void)toggleSound {BOOL enabled=![NSUserDefaults.standardUserDefaults boolForKey:@"atelier.sound"];[NSUserDefaults.standardUserDefaults setBool:enabled forKey:@"atelier.sound"];if(!enabled)[[MCSoundPlayer shared] stop];else [[MCSoundPlayer shared] play:@"load"];[self renderScreen];}
@end
