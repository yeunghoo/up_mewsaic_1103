//
//  MCPalette.m
//  loop_miao
//

#import "MCPalette.h"

@implementation MCPalette

+ (UIColor *)colorForKey:(NSString *)key {
    static NSDictionary<NSString *, UIColor *> *palette;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        palette = @{
            @"B": [UIColor colorWithRed:0.05 green:0.55 blue:1.0 alpha:1],
            @"Y": [UIColor colorWithRed:1.0 green:0.75 blue:0.03 alpha:1],
            @"P": [UIColor colorWithRed:0.72 green:0.12 blue:0.95 alpha:1],
            // 西瓜：深绿瓜皮、浅绿条纹、白色瓜瓤、红肉、黑籽
            @"G": [UIColor colorWithRed:0.02 green:0.56 blue:0.29 alpha:1.0],  // 深绿
            @"L": [UIColor colorWithRed:0.49 green:0.88 blue:0.04 alpha:1.0],  // 浅绿
            @"W": [UIColor colorWithRed:1.0 green:0.94 blue:0.79 alpha:1.0],  // 白
            @"R": [UIColor colorWithRed:1.0 green:0.16 blue:0.31 alpha:1.0],  // 红
            // 籽埋在亮红的果肉里，够黑才像籽。方块不再压暗之后这个黑度是安全的，
            // 描边也能保证边上那几颗不至于糊进深色底
            @"K": [UIColor colorWithRed:0.21 green:0.12 blue:0.34 alpha:1.0],  // 黑籽
        };
    });
    return palette[key] ?: UIColor.magentaColor;
}

+ (NSString *)nameForKey:(NSString *)key {
    static NSDictionary<NSString *, NSString *> *names;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        names = @{@"B": @"Sky blue", @"Y": @"Sun yellow", @"P": @"Violet", @"G": @"Fern", @"L": @"Lime", @"W": @"Cream", @"R": @"Pink red", @"K": @"Ink"};
    });
    return names[key] ?: key;
}

+ (BOOL)isLightColorForKey:(NSString *)key {
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [[self colorForKey:key] getRed:&r green:&g blue:&b alpha:&a];
    return (0.299 * r + 0.587 * g + 0.114 * b) > 0.62;
}

@end
