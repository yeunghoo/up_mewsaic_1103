//
//  MCPalette.h
//  loop_miao
//
//  颜色标识到展示色的映射。单独放一层，让 MCLevel / MCBoard 保持纯 Foundation，
//  规则内核就能脱离 UIKit 单独跑对照测试。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCPalette : NSObject

+ (UIColor *)colorForKey:(NSString *)key;
+ (NSString *)nameForKey:(NSString *)key;
/// 这个颜色上面该用深色字还是白字
+ (BOOL)isLightColorForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
