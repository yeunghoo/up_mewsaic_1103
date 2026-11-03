#import <UIKit/UIKit.h>
@class MCGameSession;
typedef NS_ENUM(NSInteger, MCScreen) { MCScreenHome, MCScreenMap, MCScreenBattle, MCScreenResults, MCScreenCollection, MCScreenSettings };
@interface MCGameViewController : UIViewController
@property(nonatomic,strong,readonly) MCGameSession *session;
- (void)showScreen:(MCScreen)screen;
@end
