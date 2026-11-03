//
//  MCLevel.h
//  loop_miao
//
//  关卡数据。由 tools/levelgen/blockcat.py 生成并验证可解性。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 队列里的一个篮子。容量是每个篮子自己的：同一种颜色可以配好几个容量不同的
/// 篮子，容量之和等于该色方块总数。容量与图案里那一色的暴露节奏错开多少，
/// 决定了这个篮子会不会赖在槽位上，是关卡难度的主要来源。
@interface MCBasketSpec : NSObject
@property (nonatomic, readonly, copy) NSString *colorKey;
@property (nonatomic, readonly) NSInteger capacity;
@end

@interface MCLevel : NSObject

@property (nonatomic, readonly, copy) NSString *levelId;
@property (nonatomic, readonly) NSInteger rows;
@property (nonatomic, readonly) NSInteger cols;

/// 上方槽位数量
@property (nonatomic, readonly) NSInteger slotCount;
/// 下方队列里可点击的前几个
@property (nonatomic, readonly) NSInteger windowSize;
/// 可点的后面再露出几个供预判，这些只能看不能点
@property (nonatomic, readonly) NSInteger previewSize;

/// 每行一个字符串，'.' 是图案外的空位，其余字符是颜色标识
@property (nonatomic, readonly, copy) NSArray<NSString *> *pattern;
/// 篮子队列，从左到右
@property (nonatomic, readonly, copy) NSArray<MCBasketSpec *> *baskets;

/// 队列里出现过的最大容量，内核拿它开缓冲区
@property (nonatomic, readonly) NSInteger maxCapacity;

+ (MCLevel *)demoLevel;
+ (nullable MCLevel *)levelWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
