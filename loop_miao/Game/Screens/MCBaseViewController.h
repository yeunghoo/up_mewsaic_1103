#import <UIKit/UIKit.h>
#import "MCGameViewController.h"
#import "MCGameSession.h"
#import "MCArtworkView.h"
#import "MCVisuals.h"
#import "MCPalette.h"
static inline UIColor *Ink(void) {return [UIColor colorWithRed:.10 green:.25 blue:.26 alpha:1];}
static inline UIColor *Paper(void) {return [UIColor colorWithRed:.91 green:.97 blue:.94 alpha:1];}
@interface MCBaseViewController : UIViewController
@property(nonatomic,weak) MCGameViewController *router;
@property(nonatomic,strong) MCGameSession *session;
@property(nonatomic,strong,readonly) NSArray<NSDictionary *> *catalog;
@property(nonatomic,strong,readonly) NSMutableSet<NSString *> *completed;
@property(nonatomic,strong) NSMutableArray *moves;
@property(nonatomic,strong) MCBoard *board;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) UIStackView *stack;
@property(nonatomic) NSInteger levelIndex;
@property(nonatomic) NSInteger chapter;
@property(nonatomic) BOOL busy;
@property(nonatomic,strong) NSLayoutConstraint *flexHeight;
@property(nonatomic,weak) UIView *flexView;
@property(nonatomic) NSInteger galleryPage;
@property(nonatomic,copy) NSString *screen;
- (UILabel *)label:(NSString *)text size:(CGFloat)size;
- (UIButton *)button:(NSString *)title action:(SEL)action;
- (void)action:(NSString *)title selector:(SEL)sel;
- (void)begin:(NSString *)screen;
- (UIStackView *)row;
- (MCArtworkView *)artwork:(MCLevel *)level board:(MCBoard *)board height:(CGFloat)height;
- (UIButton *)smallButton:(NSString *)symbol label:(NSString *)label action:(SEL)action;
- (void)backBar:(NSString *)title;
- (void)help;
- (void)message:(NSString *)title body:(NSString *)body;
- (NSInteger)unlocked;
- (void)prepareForNavigation;
- (void)home;
- (void)levels;
- (void)collection;
- (void)settings;
- (void)daily;
- (void)game;
- (void)finish;
- (void)save;
- (void)start:(NSInteger)index moves:(NSArray *)moves;
- (void)continueGame;
- (void)nextLevel;
@end
