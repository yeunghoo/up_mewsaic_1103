#import <UIKit/UIKit.h>
#import "MCBoard.h"
@interface MCArtworkView : UIView
@property(nonatomic,strong) MCLevel *level;
@property(nonatomic,strong) MCBoard *board;
@property(nonatomic,strong) NSMutableDictionary<NSNumber *,NSString *> *displayedColors;
@end
