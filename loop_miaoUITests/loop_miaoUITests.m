#import <XCTest/XCTest.h>
@interface loop_miaoUITests : XCTestCase
@end
@implementation loop_miaoUITests
- (void)testPrivacyAccess {
    XCUIApplication *app=[XCUIApplication new];[app launch];
    XCTAssertTrue([app.buttons[@"play"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"Settings"] tap];
    [self assertInside:app.buttons[@"privacy"] app:app];
    XCTAssertTrue(app.buttons[@"privacy"].hittable);[app.buttons[@"privacy"] tap];
    XCUIElement *policy=app.textViews[@"privacy-policy"];
    XCTAssertTrue([policy waitForExistenceWithTimeout:3]);
    XCTAssertTrue([policy.value containsString:@"aclanerdenajshhd@icloud.com"]);
    XCTAssertTrue([policy.value containsString:@"We do not collect or transmit personal data"]);
    [app.buttons[@"Done"] tap];XCTAssertTrue(app.buttons[@"privacy"].hittable);
}
- (void)capture:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *a=[XCTAttachment attachmentWithScreenshot:app.screenshot];a.name=name;a.lifetime=XCTAttachmentLifetimeKeepAlways;[self addAttachment:a];
}
- (void)testCampaignFlow {
    self.continueAfterFailure=NO;XCUIApplication *app=[XCUIApplication new];app.launchArguments=@[@"-atelier.taught",@"YES"];[app launch];
    XCTAssertTrue([app.buttons[@"play"] waitForExistenceWithTimeout:5]);XCTAssertTrue(app.buttons[@"map"].hittable);[self capture:app name:@"Home"];
    [app.buttons[@"map"] tap];XCTAssertTrue(app.buttons[@"level-1"].hittable);XCTAssertTrue(app.buttons[@"level-20"].exists);[self capture:app name:@"Map"];
    [app.buttons[@"level-1"] tap];
    XCTAssertTrue(app.buttons[@"basket-0"].hittable);XCTAssertTrue(app.buttons[@"Restart"].hittable);XCTAssertTrue(app.buttons[@"Undo"].hittable);[self capture:app name:@"Cannons"];
    [app.buttons[@"basket-0"] tap];[NSThread sleepForTimeInterval:2.2];[app.buttons[@"Undo"] tap];XCTAssertTrue(app.buttons[@"basket-0"].exists);
    for(NSInteger i=0;i<40;i++){
        if(app.staticTexts[@"Colorfully cleared!"].exists)break;
        if(![app.buttons[[NSString stringWithFormat:@"basket-%ld",(long)i]] exists])break;
        XCUIElement *b=app.buttons[[NSString stringWithFormat:@"basket-%ld",(long)i]];XCTNSPredicateExpectation *ready=[[XCTNSPredicateExpectation alloc]initWithPredicate:[NSPredicate predicateWithFormat:@"exists == YES AND enabled == YES"] object:b];XCTAssertEqual([XCTWaiter waitForExpectations:@[ready] timeout:45],XCTWaiterResultCompleted);[b tap];[NSThread sleepForTimeInterval:.3];
    }
    XCTAssertTrue([app.staticTexts[@"Colorfully cleared!"] waitForExistenceWithTimeout:45]);XCTAssertTrue(app.buttons[@"Next adventure  →"].hittable);[self capture:app name:@"Victory"];
    [app.buttons[@"Next adventure  →"] tap];XCTAssertTrue(app.staticTexts[@"Tea Break"].exists);
    [app.buttons[@"basket-0"] tap];[NSThread sleepForTimeInterval:2.2];[app terminate];[app launch];[app.buttons[@"play"] tap];XCTAssertTrue(app.staticTexts[@"Tea Break"].exists);XCTAssertFalse(app.buttons[@"basket-0"].exists);
}
- (void)assertInside:(XCUIElement *)element app:(XCUIApplication *)app {
    XCTAssertTrue(element.exists);CGRect bounds=CGRectInset(app.frame,-1,-1);XCTAssertTrue(CGRectContainsRect(bounds,element.frame),@"Clipped element: %@ %@",element.identifier,NSStringFromCGRect(element.frame));
}
- (void)testDeviceLayout {
    XCUIApplication *app=[XCUIApplication new];app.launchArguments=@[@"-atelier.taught",@"YES"];[app launch];
    XCTAssertTrue([app.buttons[@"play"] waitForExistenceWithTimeout:5]);XCTAssertLessThan(app.staticTexts[@"Mewsaic Nook"].frame.size.height,80);[self assertInside:app.buttons[@"map"] app:app];[self capture:app name:@"Device-Home"];
    [app.buttons[@"Settings"] tap];[self assertInside:app.staticTexts[@"Mewsaic Nook · Version 1.0.0\nOriginal procedural artwork and a cozy place to think."] app:app];[app.buttons[@"Home"] tap];
    [app.buttons[@"Collection"] tap];[self assertInside:app.buttons[@"Next ›"] app:app];[app.buttons[@"Home"] tap];
    [app.buttons[@"map"] tap];[self assertInside:app.buttons[@"level-20"] app:app];[self assertInside:app.buttons[@"Next ›"] app:app];[self capture:app name:@"Device-Map"];
    [app.buttons[@"level-1"] tap];XCTAssertTrue(app.buttons[@"Restart"].hittable);[self assertInside:app.buttons[@"Restart"] app:app];[self assertInside:app.buttons[@"basket-0"] app:app];[self capture:app name:@"Device-Battle"];
}
- (void)testDenseBoardLayout {
    XCUIApplication *app=[XCUIApplication new];app.launchArguments=@[@"-atelier.taught",@"YES",@"-MCPreviewLevel",@"199"];[app launch];
    XCTAssertTrue([app.staticTexts[@"Starry Rocket"] waitForExistenceWithTimeout:5]);
    XCTAssertTrue(app.buttons[@"Restart"].hittable);[self assertInside:app.buttons[@"Restart"] app:app];
    for(int i=0;i<5;i++)[self assertInside:app.buttons[[NSString stringWithFormat:@"basket-%d",i]] app:app];
    [self capture:app name:@"Device-Dense-200"];
}
- (void)testResultLayout {
    XCUIApplication *app=[XCUIApplication new];app.launchArguments=@[@"-atelier.taught",@"YES",@"-MCPreviewLevel",@"0",@"-MCPreviewWin",@"YES"];[app launch];
    XCTAssertTrue([app.staticTexts[@"Colorfully cleared!"] waitForExistenceWithTimeout:5]);
    XCTAssertTrue(app.buttons[@"Next adventure  →"].hittable);[self assertInside:app.buttons[@"Adventure map"] app:app];[self capture:app name:@"Device-Victory"];
}
- (void)testConcurrentLoadAndSound {
    XCUIApplication *app=[XCUIApplication new];app.launchArguments=@[@"-atelier.taught",@"YES"];[app launch];
    [app.buttons[@"Settings"] tap];
    XCUIElement *on=app.buttons[@"Sound effects: On"],*off=app.buttons[@"Sound effects: Off"];
    if(on.exists){[on tap];XCTAssertTrue(off.exists);[off tap];}else{[off tap];XCTAssertTrue(on.exists);}
    [app.buttons[@"Home"] tap];[app.buttons[@"map"] tap];[app.buttons[@"level-1"] tap];
    XCTAssertTrue(app.otherElements[@"cannon-2"].exists);XCTAssertFalse(app.otherElements[@"cannon-3"].exists);
    [app.buttons[@"basket-0"] tap];XCTAssertTrue(app.buttons[@"basket-1"].enabled);[app.buttons[@"basket-1"] tap];
    XCTAssertTrue(app.buttons[@"Undo"].enabled);[self capture:app name:@"Concurrent-cannons"];
    [app.buttons[@"Undo"] tap];XCTAssertTrue(app.buttons[@"basket-1"].exists);
}
- (void)testDailyLayoutAndTimeout {
    self.continueAfterFailure=NO;
    XCUIApplication *app=[XCUIApplication new];app.launchArguments=@[@"-atelier.taught",@"YES",@"-MCStoreScene",@"home"];[app launch];
    [self assertInside:app.buttons[@"daily"] app:app];[self capture:app name:@"Daily-New-Home"];
    [app.buttons[@"daily"] tap];XCTAssertTrue([app.staticTexts[@"daily-countdown"] waitForExistenceWithTimeout:5]);XCTAssertFalse(app.buttons[@"start-daily"].exists);[self assertInside:app.buttons[@"Restart"] app:app];[self capture:app name:@"Daily-Direct-Entry"];
    [app terminate];app.launchArguments=@[@"-atelier.taught",@"YES",@"-MCPreviewDaily",@"YES",@"-MCUITesting",@"YES",@"-MCDailySeconds",@"120"];[app launch];
    XCTAssertTrue([app.staticTexts[@"daily-countdown"] waitForExistenceWithTimeout:5]);
    [self assertInside:app.buttons[@"Restart"] app:app];[self assertInside:app.buttons[@"basket-0"] app:app];
    CGFloat width=app.buttons[@"basket-0"].frame.size.width;
    [app.buttons[@"basket-0"] tap];XCTAssertEqualWithAccuracy(width,app.buttons[@"basket-1"].frame.size.width,.5);
    [self capture:app name:@"Daily-Playing"];
    [app terminate];app.launchArguments=@[@"-MCPreviewDaily",@"YES",@"-MCUITesting",@"YES",@"-MCDailySeconds",@"12"];[app launch];
    [app.buttons[@"How to play"] tap];
    XCTAssertTrue([app.alerts[@"Time's up!"] waitForExistenceWithTimeout:18]);
    [app.buttons[@"Try again"] tap];XCTAssertFalse(app.alerts[@"Time's up!"].exists);XCTAssertTrue(app.staticTexts[@"daily-countdown"].exists);
    [XCUIDevice.sharedDevice pressButton:XCUIDeviceButtonHome];[NSThread sleepForTimeInterval:13];[app activate];
    XCTAssertTrue([app.alerts[@"Time's up!"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"Back to home"] tap];XCTAssertTrue(app.buttons[@"play"].hittable);
    [app terminate];app.launchArguments=@[@"-MCStoreScene",@"daily-win"];[app launch];
    XCTAssertTrue([app.staticTexts[@"Colorfully cleared!"] waitForExistenceWithTimeout:5]);[self assertInside:app.buttons[@"Back to home"] app:app];[self capture:app name:@"Daily-Win"];
}
- (void)testDailyResultLayout {
    XCUIApplication *app=[XCUIApplication new];app.launchArguments=@[@"-MCStoreScene",@"daily-win"];[app launch];
    XCTAssertTrue([app.staticTexts[@"Colorfully cleared!"] waitForExistenceWithTimeout:5]);[self assertInside:app.buttons[@"Back to home"] app:app];[self capture:app name:@"Daily-Win-Layout"];
}
- (void)testAmmoCardSizeAtQueueTail {
    XCUIApplication *app=[XCUIApplication new];app.launchArguments=@[@"-atelier.taught",@"YES",@"-MCPreviewLevel",@"0"];[app launch];CGFloat width=app.buttons[@"basket-0"].frame.size.width;
    [app terminate];app.launchArguments=@[@"-atelier.taught",@"YES",@"-MCPreviewTail",@"YES"];[app launch];
    XCUIElementQuery *packs=[app.buttons matchingPredicate:[NSPredicate predicateWithFormat:@"identifier BEGINSWITH 'basket-'"]];XCTAssertEqual(packs.count,1);XCTAssertEqualWithAccuracy(width,packs.firstMatch.frame.size.width,.5);
    [self capture:app name:@"Fixed-Last-Ammo-Card"];
}
- (void)testDailyDirectEntryAndExpiredRetry {
    self.continueAfterFailure=NO;XCUIApplication *app=[XCUIApplication new];
    app.launchArguments=@[@"-atelier.taught",@"YES",@"-MCUITesting",@"YES",@"-MCSeedExpiredDaily",@"YES"];[app launch];
    [app.buttons[@"daily"] tap];XCTAssertTrue([app.staticTexts[@"daily-countdown"] waitForExistenceWithTimeout:5]);
    XCTAssertFalse(app.alerts[@"Time's up!"].exists);XCTAssertFalse(app.buttons[@"start-daily"].exists);
    [app.buttons[@"Home"] tap];[app.buttons[@"daily"] tap];XCTAssertFalse(app.alerts[@"Time's up!"].exists);
    // A failed attempt left by a short-clock test must not leak into a normal launch.
    [app terminate];app.launchArguments=@[@"-MCPreviewDaily",@"YES",@"-MCUITesting",@"YES",@"-MCDailySeconds",@"8"];[app launch];
    XCTAssertTrue([app.alerts[@"Time's up!"] waitForExistenceWithTimeout:12]);[app.buttons[@"Back to home"] tap];
    [app.buttons[@"daily"] tap];XCTAssertFalse(app.alerts[@"Time's up!"].exists);XCTAssertTrue(app.staticTexts[@"daily-countdown"].exists);
    [app terminate];app.launchArguments=@[@"-MCStoreScene",@"home"];[app launch];[app.buttons[@"daily"] tap];
    XCTAssertFalse(app.alerts[@"Time's up!"].exists);NSString *clock=app.staticTexts[@"daily-countdown"].label;
    XCTAssertTrue([clock containsString:@"01:"]||[clock containsString:@"02:"],@"Test clock leaked: %@",clock);
    [self capture:app name:@"Daily-Fresh-After-Test"];
}
- (void)testVariedFrameLayouts {
    XCUIApplication *app=[XCUIApplication new];
    for(NSNumber *index in @[@0,@1,@2,@19,@99,@199]){
        app.launchArguments=@[@"-atelier.taught",@"YES",@"-MCPreviewLevel",index.stringValue];[app launch];
        XCTAssertTrue([app.buttons[@"basket-0"] waitForExistenceWithTimeout:5]);[self assertInside:app.buttons[@"Restart"] app:app];
        [self capture:app name:[NSString stringWithFormat:@"Frame-Level-%ld",(long)index.integerValue+1]];[app terminate];
    }
}
@end
