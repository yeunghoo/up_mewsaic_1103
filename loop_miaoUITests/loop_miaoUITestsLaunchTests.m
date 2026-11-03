//
//  loop_miaoUITestsLaunchTests.m
//  loop_miaoUITests
//
//  Created by 刘冈 on 2026/9/22.
//

#import <XCTest/XCTest.h>

@interface loop_miaoUITestsLaunchTests : XCTestCase

@end

@implementation loop_miaoUITestsLaunchTests

+ (BOOL)runsForEachTargetApplicationUIConfiguration {
    return YES;
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)testLaunch {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    // Insert steps here to perform after app launch but before taking a screenshot,
    // such as logging into a test account or navigating somewhere in the app

    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];
    attachment.name = @"Launch Screen";
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

- (void)testLaunchPerformance {
    XCUIApplication *app = [XCUIApplication new];
    XCTMeasureOptions *options = [XCTMeasureOptions defaultOptions];
    options.iterationCount = 3;
    [self measureWithMetrics:@[[XCTApplicationLaunchMetric new]] options:options block:^{
        [app launch];
    }];
    XCTAssertTrue([app.buttons[@"play"] waitForExistenceWithTimeout:5]);
    XCTAssertTrue(app.buttons[@"play"].hittable);
}

@end
