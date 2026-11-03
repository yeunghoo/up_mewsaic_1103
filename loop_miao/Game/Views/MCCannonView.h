#import <UIKit/UIKit.h>
@interface MCCannonView : UIView
- (void)showColor:(UIColor *)color symbol:(NSString *)symbol filled:(NSInteger)filled capacity:(NSInteger)capacity;
- (void)land;
- (void)consumeShot;
@end
