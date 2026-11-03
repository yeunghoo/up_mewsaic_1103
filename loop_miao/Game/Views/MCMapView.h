#import <UIKit/UIKit.h>
@interface MCMapView : UIView
@property(nonatomic) NSInteger firstLevel;
@property(nonatomic) NSInteger unlockedLevel;
@property(nonatomic,strong) NSSet<NSNumber *> *finishedLevels;
@property(nonatomic,weak) id target;
@property(nonatomic) SEL action;
- (void)build;
@end
