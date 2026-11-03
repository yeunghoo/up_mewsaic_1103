#import <UIKit/UIKit.h>
#import "MCLevel.h"
@class MCDepthButton;
@interface MCAmmoTrayView : UIView
@property(nonatomic,copy,readonly) NSArray<MCDepthButton *> *buttons;
@property(nonatomic,weak) id target;
@property(nonatomic) SEL action;
- (void)showPacks:(NSArray<MCBasketSpec *> *)packs indexes:(NSArray<NSNumber *> *)indexes;
- (void)setLoadingEnabled:(BOOL)enabled;
@end
