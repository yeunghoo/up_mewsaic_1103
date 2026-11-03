#import <UIKit/UIKit.h>
/// A fixed set of compositor layers, reused for successive impacts.
@interface MCImpactBurst : NSObject
- (instancetype)initWithParent:(CALayer *)parent;
- (void)emitAt:(CGPoint)point color:(UIColor *)color;
- (void)clear;
@end
