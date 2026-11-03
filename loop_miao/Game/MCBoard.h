//
//  MCBoard.h
//  loop_miao
//
//  玩法内核。规则与 tools/levelgen/blockcat.py 完全一致：
//
//  1. 一个方块能被搬走，条件是它的四邻中有一个空格、且该空格与图案外部连通
//     （猫猫得能从外面走到它旁边）。这条规则产生「先外圈后内圈」，也允许
//     玩家从一侧挖通道提前接触内部。
//  2. 篮子进槽后，所有在场篮子自动收走当前能搬的同色方块。搬走会暴露新方块，
//     所以结算要循环到稳定，一次点击可能引发连锁。
//  3. 篮子装满即离场腾出槽位；没装满就一直占着槽位等新方块暴露。
//  4. 死局是槽位用尽且没有一个篮子还能收到方块。
//

#import <Foundation/Foundation.h>
#import "MCLevel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MCSafety) {
    /// 这一步之后确定还能通关
    MCSafetyFine,
    /// 这一步之后确定走不通了
    MCSafetyFatal,
    /// 求解器在预算内没搜完，不下结论
    MCSafetyUnknown,
};

typedef NS_ENUM(NSInteger, MCStepKind) {
    /// 一批方块被某个篮子收走
    MCStepKindTake,
    /// 某个篮子装满离场
    MCStepKindFull,
};

/// 结算过程中的一个事件，供 UI 按时间轴逐个播放动画
@interface MCStep : NSObject
@property (nonatomic, readonly) MCStepKind kind;
@property (nonatomic, readonly) NSInteger slotIndex;
@property (nonatomic, readonly, copy) NSString *colorKey;
/// 本步被搬走的方块，元素是 row * cols + col
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *indexes;
/// 本步之后篮子里的方块数
@property (nonatomic, readonly) NSInteger filled;
@end

/// 一次点击的完整结果
@interface MCMove : NSObject
@property (nonatomic, readonly) NSInteger queueIndex;
@property (nonatomic, readonly) NSInteger slotIndex;
@property (nonatomic, readonly, copy) NSString *colorKey;
@property (nonatomic, readonly) NSInteger capacity;
@property (nonatomic, readonly, copy) NSArray<MCStep *> *steps;
@end

/// 槽位上的篮子
@interface MCBasket : NSObject
@property (nonatomic, readonly, copy) NSString *colorKey;
@property (nonatomic, readonly) NSInteger filled;
@property (nonatomic, readonly) NSInteger capacity;
@end

@interface MCBoard : NSObject

- (instancetype)initWithLevel:(MCLevel *)level NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) MCLevel *level;

/// 某格当前的方块颜色，nil 表示该格是空的（图案外或已被搬走）
- (nullable NSString *)colorKeyAtIndex:(NSInteger)index;
/// 当前能被搬走的方块下标
- (NSSet<NSNumber *> *)collectibleIndexes;

/// 三个槽位，元素是 MCBasket 或 NSNull
@property (nonatomic, readonly, copy) NSArray *slots;
/// 队列里还没用过的篮子下标（含窗口外的）
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *pendingQueueIndexes;
/// 可见窗口内、当前能点的篮子下标
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *selectableQueueIndexes;
/// 下方一共露出来的篮子下标：能点的那几个，加上后面供预判的几个
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *visibleQueueIndexes;

@property (nonatomic, readonly) NSInteger remainingBlockCount;
@property (nonatomic, readonly) BOOL isWin;
@property (nonatomic, readonly) BOOL isDeadlock;

/// 把队列第 queueIndex 个篮子放进空槽位并结算。不合法则返回 nil。
- (nullable MCMove *)playBasketAtQueueIndex:(NSInteger)queueIndex;
/// Explicit empty slot for simultaneous visual volleys; used during replay too.
- (nullable MCMove *)playBasketAtQueueIndex:(NSInteger)queueIndex slotIndex:(NSInteger)slot;

/// 从当前局面出发搜索一条通关路径，返回该走哪个篮子。找不到返回 NSNotFound。
- (NSInteger)hintQueueIndex;
/// 点了某个篮子之后还能不能通关，用来在 UI 上标出会走死的选择。
/// 关卡一大，求解器可能在预算内搜不完，那就是 Unknown，别当成死路。
- (MCSafety)safetyOfQueueIndex:(NSInteger)queueIndex;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
