#import "MCAdLog.h"

void MCAdLog(NSString *format, ...) {
    va_list arguments;
    va_start(arguments,format);
    NSString *message=[[NSString alloc]initWithFormat:format arguments:arguments];
    va_end(arguments);
    // Hosted unit tests invoke delegate methods with fake ads. Make those logs
    // unmistakable; they must never be used as evidence of live network fill.
    BOOL unitTestHost = NSClassFromString(@"MCAdvertisingTests") != Nil;
    NSLog(@"[广告]%@ %@",unitTestHost?@"[单元测试环境，非真实广告验证]":@"",message);
}
