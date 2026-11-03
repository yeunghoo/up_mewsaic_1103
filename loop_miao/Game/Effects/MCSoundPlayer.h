#import <Foundation/Foundation.h>
@interface MCSoundPlayer : NSObject
+ (instancetype)shared;
- (void)play:(NSString *)effect;
- (void)stop;
@end
