#import <XCTest/XCTest.h>

@interface MCAdStartupUITests : XCTestCase
@end
@implementation MCAdStartupUITests
- (void)testDailyOfferCanReopenAndFitsSafeArea {
    self.continueAfterFailure=NO;
    XCUIApplication *app=[XCUIApplication new];[app launch];
    XCUIApplication *system=[[XCUIApplication alloc]initWithBundleIdentifier:@"com.apple.springboard"];
    XCUIElement *deny=[system.buttons matchingPredicate:[NSPredicate predicateWithFormat:@"label == %@ OR label CONTAINS %@", @"Ask App Not to Track", @"不跟踪"]].firstMatch;
    if([deny waitForExistenceWithTimeout:3])[deny tap];
    XCTAssertTrue([app.buttons[@"daily"] waitForExistenceWithTimeout:10]);[app.buttons[@"daily"] tap];
    XCUIElement *clock=app.buttons[@"daily-countdown"];
    XCTAssertTrue([clock waitForExistenceWithTimeout:5]);
    for(NSUInteger i=0;i<3;i++){
        [clock tap];
        XCUIElement *watch=app.buttons[@"watch-reward-video"];
        XCUIElement *cancel=app.buttons[@"cancel-reward-video"];
        XCTAssertTrue([watch waitForExistenceWithTimeout:5]);XCTAssertTrue(watch.hittable);XCTAssertTrue(cancel.hittable);
        XCUIElement *banner=app.otherElements[@"reward-banner-container"];
        XCTAssertTrue(banner.exists);XCTAssertTrue(CGRectContainsRect(app.frame,banner.frame));
        XCTAssertLessThanOrEqual(CGRectGetMaxY(cancel.frame),CGRectGetMinY(banner.frame));
        if(i==0){XCTAttachment *a=[XCTAttachment attachmentWithScreenshot:app.screenshot];a.name=@"Daily reward offer and banner layer";a.lifetime=XCTAttachmentLifetimeKeepAlways;[self addAttachment:a];}
        [cancel tap];XCTAssertTrue([watch waitForNonExistenceWithTimeout:5]);
        XCTAssertFalse(banner.exists);XCTAssertTrue(clock.hittable);
    }
}
- (void)testATTDenialStillAllowsGameplayAndDoesNotRepeat {
    self.continueAfterFailure = NO;
    XCUIApplication *app = [XCUIApplication new];
    app.launchArguments = @[@"-atelier.taught", @"YES"];
    [app launch];
    XCUIApplication *system = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
    XCUIElement *deny = [system.buttons matchingPredicate:[NSPredicate predicateWithFormat:@"label == %@ OR label CONTAINS %@", @"Ask App Not to Track", @"不跟踪"]].firstMatch;
    // Run on a device with no previous ATT decision for this bundle ID.
    XCTAssertTrue([deny waitForExistenceWithTimeout:15], @"Use a fresh ATT authorization state for this test.");
    XCTAttachment *prompt = [XCTAttachment attachmentWithScreenshot:system.screenshot];
    prompt.name = @"English ATT prompt"; prompt.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:prompt];
    [deny tap];
    XCTAssertTrue([app.buttons[@"play"] waitForExistenceWithTimeout:10]);
    XCTAssertTrue(app.buttons[@"play"].hittable);
    [app.buttons[@"play"] tap];
    XCTAssertTrue([app.buttons[@"basket-0"] waitForExistenceWithTimeout:5]);
    XCTAssertTrue(app.buttons[@"basket-0"].hittable);
    [app.buttons[@"basket-0"] tap];
    XCTAssertTrue(app.buttons[@"Restart"].hittable);
    [app terminate]; [app launch];
    XCTAssertTrue([app.buttons[@"play"] waitForExistenceWithTimeout:10]);
    XCTAssertFalse(deny.exists); XCTAssertTrue(app.buttons[@"play"].hittable);
    [app.buttons[@"Settings"] tap]; [app.buttons[@"privacy"] tap];
    XCUIElement *policy = app.textViews[@"privacy-policy"];
    XCTAssertTrue([policy waitForExistenceWithTimeout:5]);
    XCTAssertTrue([policy.value containsString:@"InMobi"]);
    XCTAssertTrue([policy.value containsString:@"aclanerdenajshhd@icloud.com"]);
}
@end
