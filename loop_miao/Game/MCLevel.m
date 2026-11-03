//
//  MCLevel.m
//  loop_miao
//

#import "MCLevel.h"

@interface MCBasketSpec ()
@property (nonatomic, readwrite, copy) NSString *colorKey;
@property (nonatomic, readwrite) NSInteger capacity;
@end

@implementation MCBasketSpec

- (NSString *)description {
    return [NSString stringWithFormat:@"%@%ld", self.colorKey, (long)self.capacity];
}

@end

@implementation MCLevel

+ (MCLevel *)demoLevel {
    // 一片西瓜。由 tools/levelgen/blockcat.py 生成并验证：
    // 156 个方块 / 5 种颜色 / 7 层深，19 个篮子按队首顺序点必定通关。
    //
    // 瓜皮做成深绿浅绿交替的放射状条纹，是为了避开一个陷阱：西瓜的颜色天然
    // 是同心的（皮在外、白圈、红肉在内），而剥离顺序也是同心的，两者一旦对齐
    // 每个篮子都会一上来就装满，关卡就毫无压力。条纹沿半径方向横跨好几层，
    // 正好把这种对齐打散。瓜籽也排在两圈不同半径上，所以黑篮总要等更深的
    // 籽露出来才装得满。
    //
    // 队列顺序是搜出来的：先保证「一路点队首必定通关」，再在这个前提下挑
    // 最容易让人走错的那一版。实测带噪真人失败率 7.8%，全程平均占 2.93 个
    // 槽位 —— basically 一直贴着三个槽的上限在走，错一步就没地方放篮子了。
    return [self levelWithDictionary:@{
        @"id": @"melon-01",
        @"slots": @3,
        @"window": @3,
        @"preview": @3,
        @"pattern": @[
            @"....LLLGGG....",
            @"...GGLLGGLL...",
            @"..GGWRKRRWLG..",
            @".LLWKRRRKRWGG.",
            @"GLWRRRKRRRKWGL",
            @"GGRKRKRRKRRRLL",
            @"GGRRRRRRRRRKLL",
            @"LLRRKRRRRKRRGG",
            @"LLRKRRRRRRRRGG",
            @"LGWRRKRRKRKWLG",
            @".GGWKRRRKRWLL.",
            @"..GLWRKRRWGG..",
            @"...LLGGLLGG...",
            @"....GGGLLL....",
        ],
        // 颜色 + 该篮容量。同色多篮、容量各不相同，每色容量之和等于图案里
        // 这个颜色的方块总数：G 36 / L 32 / W 12 / R 58 / K 18。
        @"baskets": @"R11 K8 G6 L7 W5 R13 W7 R9 R13 R7 R5 G10 G12 G8 L9 K4 K6 L5 L11",
    }];
}

/// 把 "R13 K6 G10" 解析成篮子列表。手写关卡时这种写法一眼能看出队列设计。
+ (NSArray<MCBasketSpec *> *)basketsFromCompactString:(NSString *)text {
    NSMutableArray<MCBasketSpec *> *out = [NSMutableArray array];
    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    for (NSString *token in [text componentsSeparatedByCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
        if (token.length < 2) continue;
        NSRange split = [token rangeOfCharacterFromSet:digits];
        if (split.location == NSNotFound || split.location == 0) continue;
        MCBasketSpec *spec = [[MCBasketSpec alloc] init];
        spec.colorKey = [token substringToIndex:split.location];
        spec.capacity = [[token substringFromIndex:split.location] integerValue];
        if (spec.capacity > 0) [out addObject:spec];
    }
    return out;
}

+ (NSArray<MCBasketSpec *> *)basketsFromArray:(NSArray<NSDictionary *> *)array {
    NSMutableArray<MCBasketSpec *> *out = [NSMutableArray array];
    for (NSDictionary *item in array) {
        MCBasketSpec *spec = [[MCBasketSpec alloc] init];
        spec.colorKey = [item[@"color"] copy];
        spec.capacity = [item[@"capacity"] integerValue];
        if (spec.colorKey.length > 0 && spec.capacity > 0) [out addObject:spec];
    }
    return out;
}

+ (nullable MCLevel *)levelWithDictionary:(NSDictionary *)dict {
    NSArray<NSString *> *pattern = dict[@"pattern"];
    id rawBaskets = dict[@"baskets"];

    NSArray<MCBasketSpec *> *baskets = nil;
    if ([rawBaskets isKindOfClass:[NSString class]]) {
        baskets = [self basketsFromCompactString:rawBaskets];
    } else if ([rawBaskets isKindOfClass:[NSArray class]]) {
        baskets = [self basketsFromArray:rawBaskets];
    }
    if (pattern.count == 0 || baskets.count == 0) return nil;

    MCLevel *level = [[MCLevel alloc] init];
    level->_levelId = [dict[@"id"] copy] ?: @"untitled";
    level->_pattern = [pattern copy];
    level->_baskets = [baskets copy];
    level->_rows = (NSInteger)pattern.count;
    level->_slotCount = [dict[@"slots"] integerValue];
    level->_windowSize = [dict[@"window"] integerValue];
    level->_previewSize = [dict[@"preview"] integerValue];

    NSInteger cols = 0;
    for (NSString *line in pattern) {
        cols = MAX(cols, (NSInteger)line.length);
    }
    level->_cols = cols;

    NSInteger maxCapacity = 0;
    for (MCBasketSpec *spec in baskets) {
        maxCapacity = MAX(maxCapacity, spec.capacity);
    }
    level->_maxCapacity = maxCapacity;
    return level;
}

@end
