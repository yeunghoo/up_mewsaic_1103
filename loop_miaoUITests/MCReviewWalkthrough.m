#import <XCTest/XCTest.h>

// Manual recording harness: normal UI interactions only, no debug game shortcuts.
@interface MCReviewWalkthrough : XCTestCase
@end
@implementation MCReviewWalkthrough
- (void)pause:(NSTimeInterval)seconds { [NSThread sleepForTimeInterval:seconds]; }
- (void)testRecordVersion100 {
    XCTSkipUnless([NSProcessInfo.processInfo.environment[@"MC_RECORD_DEMO"] isEqual:@"1"], @"Opt-in simulator demonstration");
    self.continueAfterFailure=NO;
    XCUIApplication *app=[XCUIApplication new];
    app.launchArguments=@[@"-AppleLanguages",@"(en)",@"-AppleLocale",@"en_US"];
    [XCUIDevice.sharedDevice pressButton:XCUIDeviceButtonHome];
    NSLog(@"REVIEW_RECORD_READY");[self pause:8];
    [app launch];XCTAssertTrue([app.buttons[@"play"] waitForExistenceWithTimeout:10]);[self pause:3];
    [app.buttons[@"play"] tap];
    if([app.buttons[@"Got it"] waitForExistenceWithTimeout:3]){[self pause:5];[app.buttons[@"Got it"] tap];}
    XCTAssertTrue(app.staticTexts[@"Studio Cat"].exists);[self pause:2];
    [app.buttons[@"Hint"] tap];[self pause:3];[app.buttons[@"Got it"] tap];
    [app.buttons[@"basket-0"] tap];[self pause:2.5];[app.buttons[@"Undo"] tap];[self pause:2];
    for(NSInteger i=0;i<40;i++){
        if(app.staticTexts[@"Colorfully cleared!"].exists)break;
        XCUIElement *card=app.buttons[[NSString stringWithFormat:@"basket-%ld",(long)i]];
        if(!card.exists)break;
        XCTNSPredicateExpectation *ready=[[XCTNSPredicateExpectation alloc]initWithPredicate:[NSPredicate predicateWithFormat:@"exists == YES AND enabled == YES"] object:card];
        XCTAssertEqual([XCTWaiter waitForExpectations:@[ready] timeout:45],XCTWaiterResultCompleted);
        [card tap];[self pause:1];
    }
    XCTAssertTrue([app.staticTexts[@"Colorfully cleared!"] waitForExistenceWithTimeout:45]);[self pause:5];
    [app.buttons[@"Next adventure  →"] tap];XCTAssertTrue(app.staticTexts[@"Tea Break"].exists);[self pause:3];
    [app.buttons[@"Adventure map"] tap];[self pause:4];[app.buttons[@"Home"] tap];
    [app.buttons[@"Collection"] tap];[self pause:4];[app.buttons[@"Home"] tap];
    [app.buttons[@"daily"] tap];XCTAssertTrue([app.buttons[@"daily-countdown"] waitForExistenceWithTimeout:5]);[self pause:3];
    [app.buttons[@"basket-0"] tap];[self pause:2];
    if(app.buttons[@"basket-1"].enabled)[app.buttons[@"basket-1"] tap];[self pause:6];
    [app.buttons[@"Home"] tap];[app.buttons[@"Settings"] tap];[self pause:5];
    [app.buttons[@"Sound effects: On"] tap];[self pause:1];[app.buttons[@"Sound effects: Off"] tap];
    [app.buttons[@"privacy"] tap];[self pause:5];[app.textViews[@"privacy-policy"] swipeUp];[self pause:3];
    [app.buttons[@"Done"] tap];[app.buttons[@"Home"] tap];[self pause:3];
    NSLog(@"REVIEW_RECORD_DONE");[self pause:3];
}
@end
