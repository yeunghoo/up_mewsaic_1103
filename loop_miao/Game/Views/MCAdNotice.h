#import <UIKit/UIKit.h>

@interface MCAdNotice : NSObject
/// Small, noninteractive, automatically dismissed notice inside the top safe area.
+ (void)showText:(NSString *)text inView:(UIView *)view success:(BOOL)success;
@end
