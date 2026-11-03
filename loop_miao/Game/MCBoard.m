//
//  MCBoard.m
//  loop_miao
//

#import "MCBoard.h"

#pragma mark - 纯 C 规则内核

typedef struct {
    int8_t color;      // -1 表示空槽
    int8_t filled;
    int8_t capacity;   // 每个篮子自带的容量，不是全局常量
} MCSlotState;

typedef struct {
    NSInteger rows, cols, cellCount;
    NSInteger slotCount, windowSize;
    NSInteger basketCount, maxCapacity;
    const int8_t *basketColors;
    const int8_t *basketCaps;
} MCRules;

/// 算出当前哪些方块能被搬走：从图案外部洪泛空格，四邻沾到空气的方块就能搬。
static void MCComputeCollectible(const MCRules *r, const int8_t *cells,
                                 uint8_t *outCollectible, uint8_t *airScratch,
                                 NSInteger *stackScratch) {
    const NSInteger PW = r->cols + 2;
    const NSInteger PH = r->rows + 2;
    const NSInteger PN = PW * PH;

    memset(airScratch, 0, (size_t)PN);
    memset(outCollectible, 0, (size_t)r->cellCount);

    // 从左上角那圈虚拟边界出发，只走没有方块的格子。
    // 图案内部的封闭空腔洪泛不到，所以腔壁的方块搬不走。
    NSInteger top = 0;
    airScratch[0] = 1;
    stackScratch[top++] = 0;

    static const NSInteger dr[4] = {-1, 1, 0, 0};
    static const NSInteger dc[4] = {0, 0, -1, 1};

    while (top > 0) {
        const NSInteger p = stackScratch[--top];
        const NSInteger pr = p / PW;
        const NSInteger pc = p % PW;
        for (int k = 0; k < 4; k++) {
            const NSInteger nr = pr + dr[k];
            const NSInteger nc = pc + dc[k];
            if (nr < 0 || nr >= PH || nc < 0 || nc >= PW) continue;
            const NSInteger np = nr * PW + nc;
            if (airScratch[np]) continue;
            const NSInteger gr = nr - 1;
            const NSInteger gc = nc - 1;
            if (gr >= 0 && gr < r->rows && gc >= 0 && gc < r->cols &&
                cells[gr * r->cols + gc] >= 0) {
                continue;  // 有方块挡着，猫猫过不去
            }
            airScratch[np] = 1;
            stackScratch[top++] = np;
        }
    }

    for (NSInteger row = 0; row < r->rows; row++) {
        for (NSInteger col = 0; col < r->cols; col++) {
            const NSInteger idx = row * r->cols + col;
            if (cells[idx] < 0) continue;
            const NSInteger pr = row + 1;
            const NSInteger pc = col + 1;
            if (airScratch[(pr - 1) * PW + pc] || airScratch[(pr + 1) * PW + pc] ||
                airScratch[pr * PW + pc - 1] || airScratch[pr * PW + pc + 1]) {
                outCollectible[idx] = 1;
            }
        }
    }
}

typedef void (^MCTakeHandler)(NSInteger slot, int8_t color, const NSInteger *indexes,
                              NSInteger count, NSInteger filled);
typedef void (^MCFullHandler)(NSInteger slot, int8_t color);

/// 所有在场篮子自动收集，循环到稳定。搬走方块会暴露新方块，所以会连锁。
static void MCSettle(const MCRules *r, int8_t *cells, MCSlotState *slots,
                     MCTakeHandler onTake, MCFullHandler onFull) {
    const NSInteger PN = (r->rows + 2) * (r->cols + 2);
    uint8_t *ready = (uint8_t *)malloc((size_t)r->cellCount);
    uint8_t *air = (uint8_t *)malloc((size_t)PN);
    NSInteger *stack = (NSInteger *)malloc(sizeof(NSInteger) * (size_t)PN);
    NSInteger *taken = (NSInteger *)malloc(sizeof(NSInteger) * (size_t)r->maxCapacity);

    BOOL changed = YES;
    while (changed) {
        changed = NO;
        MCComputeCollectible(r, cells, ready, air, stack);
        for (NSInteger s = 0; s < r->slotCount; s++) {
            if (slots[s].color < 0) continue;
            const int8_t color = slots[s].color;
            const NSInteger room = slots[s].capacity - slots[s].filled;
            NSInteger n = 0;
            for (NSInteger idx = 0; idx < r->cellCount && n < room; idx++) {
                if (ready[idx] && cells[idx] == color) {
                    cells[idx] = -1;
                    taken[n++] = idx;
                }
            }
            if (n == 0) continue;
            changed = YES;
            slots[s].filled = (int8_t)(slots[s].filled + n);
            if (onTake) onTake(s, color, taken, n, slots[s].filled);
            if (slots[s].filled >= slots[s].capacity) {
                slots[s].color = -1;
                slots[s].filled = 0;
                slots[s].capacity = 0;
                if (onFull) onFull(s, color);
            }
        }
    }

    free(ready);
    free(air);
    free(stack);
    free(taken);
}

/// 队列里可见窗口内、还没用过的篮子下标
static NSInteger MCSelectable(const MCRules *r, uint64_t used, NSInteger *out) {
    NSInteger n = 0;
    for (NSInteger i = 0; i < r->basketCount && n < r->windowSize; i++) {
        if (used & (1ULL << i)) continue;
        out[n++] = i;
    }
    return n;
}

static NSInteger MCFirstFreeSlot(const MCRules *r, const MCSlotState *slots) {
    for (NSInteger s = 0; s < r->slotCount; s++) {
        if (slots[s].color < 0) return s;
    }
    return NSNotFound;
}

static NSInteger MCRemaining(const MCRules *r, const int8_t *cells) {
    NSInteger n = 0;
    for (NSInteger i = 0; i < r->cellCount; i++) {
        if (cells[i] >= 0) n++;
    }
    return n;
}

/// 从当前局面出发能否清空棋盘。outFirstPick 会填上第一步该点哪个篮子。
///
/// budget 是节点预算。西瓜那种十九个篮子的关卡，穷尽搜索会让主线程卡住，
/// 所以搜不动就提前收手：budget 归零后返回的 NO 只代表「没搜出来」，
/// 调用方要靠 budget 是否见底来区分它和真正的「无解」。
static BOOL MCSolvable(const MCRules *r, const int8_t *cells, const MCSlotState *slots,
                       uint64_t used, NSMutableSet<NSData *> *visited,
                       NSInteger *budget, NSInteger *outFirstPick) {
    if (MCRemaining(r, cells) == 0) return YES;
    if (budget && --(*budget) <= 0) return NO;

    const size_t slotBytes = sizeof(MCSlotState) * (size_t)r->slotCount;
    NSMutableData *fingerprint =
        [NSMutableData dataWithCapacity:(size_t)r->cellCount + slotBytes + sizeof(used)];
    [fingerprint appendBytes:cells length:(size_t)r->cellCount];
    [fingerprint appendBytes:slots length:slotBytes];
    [fingerprint appendBytes:&used length:sizeof(used)];
    if ([visited containsObject:fingerprint]) return NO;
    [visited addObject:fingerprint];

    // 每步都会用掉一个篮子，used 单调递增，所以状态图无环
    NSInteger options[64];
    const NSInteger count = MCSelectable(r, used, options);
    for (NSInteger i = 0; i < count; i++) {
        const NSInteger slot = MCFirstFreeSlot(r, slots);
        if (slot == NSNotFound) break;

        int8_t *nextCells = (int8_t *)malloc((size_t)r->cellCount);
        memcpy(nextCells, cells, (size_t)r->cellCount);
        MCSlotState *nextSlots = (MCSlotState *)malloc(slotBytes);
        memcpy(nextSlots, slots, slotBytes);

        nextSlots[slot].color = r->basketColors[options[i]];
        nextSlots[slot].filled = 0;
        nextSlots[slot].capacity = r->basketCaps[options[i]];
        MCSettle(r, nextCells, nextSlots, nil, nil);

        const BOOL ok = MCSolvable(r, nextCells, nextSlots,
                                   used | (1ULL << options[i]), visited, budget, NULL);
        free(nextCells);
        free(nextSlots);

        if (ok) {
            if (outFirstPick) *outFirstPick = options[i];
            return YES;
        }
        if (budget && *budget <= 0) return NO;
    }
    return NO;
}

#pragma mark - 事件对象

@interface MCStep ()
@property (nonatomic, readwrite) MCStepKind kind;
@property (nonatomic, readwrite) NSInteger slotIndex;
@property (nonatomic, readwrite, copy) NSString *colorKey;
@property (nonatomic, readwrite, copy) NSArray<NSNumber *> *indexes;
@property (nonatomic, readwrite) NSInteger filled;
@end

@implementation MCStep
@end

@interface MCMove ()
@property (nonatomic, readwrite) NSInteger queueIndex;
@property (nonatomic, readwrite) NSInteger slotIndex;
@property (nonatomic, readwrite, copy) NSString *colorKey;
@property (nonatomic, readwrite) NSInteger capacity;
@property (nonatomic, readwrite, copy) NSArray<MCStep *> *steps;
@end

@implementation MCMove
@end

@interface MCBasket ()
@property (nonatomic, readwrite, copy) NSString *colorKey;
@property (nonatomic, readwrite) NSInteger filled;
@property (nonatomic, readwrite) NSInteger capacity;
@end

@implementation MCBasket
@end

#pragma mark - MCBoard

@implementation MCBoard {
    MCRules _rules;
    int8_t *_cells;
    int8_t *_initialCells;
    int8_t *_basketColors;
    int8_t *_basketCaps;
    MCSlotState *_slots;
    uint64_t _used;
    NSArray<NSString *> *_colorKeys;
}

- (instancetype)initWithLevel:(MCLevel *)level {
    NSParameterAssert(level.baskets.count <= 64);
    self = [super init];
    if (!self) return nil;

    _level = level;

    // 颜色标识去重建表，之后内核里一律用 int8 索引
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    for (NSString *line in level.pattern) {
        for (NSInteger i = 0; i < (NSInteger)line.length; i++) {
            NSString *ch = [line substringWithRange:NSMakeRange((NSUInteger)i, 1)];
            if ([ch isEqualToString:@"."]) continue;
            if (![keys containsObject:ch]) [keys addObject:ch];
        }
    }
    for (MCBasketSpec *spec in level.baskets) {
        if (![keys containsObject:spec.colorKey]) [keys addObject:spec.colorKey];
    }
    _colorKeys = [keys copy];

    _rules.rows = level.rows;
    _rules.cols = level.cols;
    _rules.cellCount = level.rows * level.cols;
    _rules.slotCount = level.slotCount;
    _rules.windowSize = level.windowSize;
    _rules.basketCount = (NSInteger)level.baskets.count;
    _rules.maxCapacity = level.maxCapacity;

    _initialCells = (int8_t *)malloc((size_t)_rules.cellCount);
    for (NSInteger row = 0; row < _rules.rows; row++) {
        NSString *line = level.pattern[(NSUInteger)row];
        for (NSInteger col = 0; col < _rules.cols; col++) {
            int8_t v = -1;
            if (col < (NSInteger)line.length) {
                NSString *ch = [line substringWithRange:NSMakeRange((NSUInteger)col, 1)];
                if (![ch isEqualToString:@"."]) {
                    v = (int8_t)[_colorKeys indexOfObject:ch];
                }
            }
            _initialCells[row * _rules.cols + col] = v;
        }
    }

    _basketColors = (int8_t *)malloc((size_t)_rules.basketCount);
    _basketCaps = (int8_t *)malloc((size_t)_rules.basketCount);
    for (NSInteger i = 0; i < _rules.basketCount; i++) {
        MCBasketSpec *spec = level.baskets[(NSUInteger)i];
        _basketColors[i] = (int8_t)[_colorKeys indexOfObject:spec.colorKey];
        _basketCaps[i] = (int8_t)spec.capacity;
    }
    _rules.basketColors = _basketColors;
    _rules.basketCaps = _basketCaps;

    _cells = (int8_t *)malloc((size_t)_rules.cellCount);
    _slots = (MCSlotState *)malloc(sizeof(MCSlotState) * (size_t)_rules.slotCount);

    [self reset];
    return self;
}

- (void)dealloc {
    free(_cells);
    free(_initialCells);
    free(_basketColors);
    free(_basketCaps);
    free(_slots);
}

- (void)reset {
    memcpy(_cells, _initialCells, (size_t)_rules.cellCount);
    for (NSInteger s = 0; s < _rules.slotCount; s++) {
        _slots[s].color = -1;
        _slots[s].filled = 0;
        _slots[s].capacity = 0;
    }
    _used = 0;
    // 开局也要结算一次，保持和求解器一致（此时槽位空着，不会有动作）
    MCSettle(&_rules, _cells, _slots, nil, nil);
}

#pragma mark 查询

- (nullable NSString *)colorKeyAtIndex:(NSInteger)index {
    if (index < 0 || index >= _rules.cellCount) return nil;
    const int8_t v = _cells[index];
    return v < 0 ? nil : _colorKeys[(NSUInteger)v];
}

- (NSSet<NSNumber *> *)collectibleIndexes {
    const NSInteger PN = (_rules.rows + 2) * (_rules.cols + 2);
    uint8_t *ready = (uint8_t *)malloc((size_t)_rules.cellCount);
    uint8_t *air = (uint8_t *)malloc((size_t)PN);
    NSInteger *stack = (NSInteger *)malloc(sizeof(NSInteger) * (size_t)PN);

    MCComputeCollectible(&_rules, _cells, ready, air, stack);

    NSMutableSet<NSNumber *> *result = [NSMutableSet set];
    for (NSInteger i = 0; i < _rules.cellCount; i++) {
        if (ready[i]) [result addObject:@(i)];
    }
    free(ready);
    free(air);
    free(stack);
    return result;
}

- (NSArray *)slots {
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:(NSUInteger)_rules.slotCount];
    for (NSInteger s = 0; s < _rules.slotCount; s++) {
        if (_slots[s].color < 0) {
            [out addObject:[NSNull null]];
        } else {
            MCBasket *basket = [[MCBasket alloc] init];
            basket.colorKey = _colorKeys[(NSUInteger)_slots[s].color];
            basket.filled = _slots[s].filled;
            basket.capacity = _slots[s].capacity;
            [out addObject:basket];
        }
    }
    return out;
}

- (NSArray<NSNumber *> *)pendingQueueIndexes {
    NSMutableArray<NSNumber *> *out = [NSMutableArray array];
    for (NSInteger i = 0; i < _rules.basketCount; i++) {
        if (!(_used & (1ULL << i))) [out addObject:@(i)];
    }
    return out;
}

- (NSArray<NSNumber *> *)selectableQueueIndexes {
    NSInteger options[64];
    const NSInteger count = MCSelectable(&_rules, _used, options);
    NSMutableArray<NSNumber *> *out = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (NSInteger i = 0; i < count; i++) [out addObject:@(options[i])];
    return out;
}

- (NSArray<NSNumber *> *)visibleQueueIndexes {
    const NSInteger limit = _rules.windowSize + _level.previewSize;
    NSMutableArray<NSNumber *> *out = [NSMutableArray array];
    for (NSInteger i = 0; i < _rules.basketCount && (NSInteger)out.count < limit; i++) {
        if (!(_used & (1ULL << i))) [out addObject:@(i)];
    }
    return out;
}

- (NSInteger)remainingBlockCount {
    return MCRemaining(&_rules, _cells);
}

- (BOOL)isWin {
    return self.remainingBlockCount == 0;
}

- (BOOL)isDeadlock {
    if (self.isWin) return NO;
    // 结算已经跑到稳定，所以此刻推进局面的唯一办法就是再上一个篮子
    const BOOL hasFreeSlot = MCFirstFreeSlot(&_rules, _slots) != NSNotFound;
    return !(hasFreeSlot && self.selectableQueueIndexes.count > 0);
}

#pragma mark 操作

- (nullable MCMove *)playBasketAtQueueIndex:(NSInteger)queueIndex {
    return [self playBasketAtQueueIndex:queueIndex slotIndex:MCFirstFreeSlot(&_rules, _slots)];
}

- (nullable MCMove *)playBasketAtQueueIndex:(NSInteger)queueIndex slotIndex:(NSInteger)slot {
    if (![self.selectableQueueIndexes containsObject:@(queueIndex)]) return nil;
    if (slot < 0 || slot >= _rules.slotCount || _slots[slot].color >= 0) return nil;

    _slots[slot].color = _basketColors[queueIndex];
    _slots[slot].filled = 0;
    _slots[slot].capacity = _basketCaps[queueIndex];
    _used |= (1ULL << queueIndex);

    NSMutableArray<MCStep *> *steps = [NSMutableArray array];
    NSArray<NSString *> *colorKeys = _colorKeys;

    MCSettle(&_rules, _cells, _slots,
             ^(NSInteger s, int8_t color, const NSInteger *indexes, NSInteger count,
               NSInteger filled) {
        NSMutableArray<NSNumber *> *list = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
        for (NSInteger i = 0; i < count; i++) [list addObject:@(indexes[i])];
        MCStep *step = [[MCStep alloc] init];
        step.kind = MCStepKindTake;
        step.slotIndex = s;
        step.colorKey = colorKeys[(NSUInteger)color];
        step.indexes = list;
        step.filled = filled;
        [steps addObject:step];
    },
             ^(NSInteger s, int8_t color) {
        MCStep *step = [[MCStep alloc] init];
        step.kind = MCStepKindFull;
        step.slotIndex = s;
        step.colorKey = colorKeys[(NSUInteger)color];
        step.indexes = @[];
        [steps addObject:step];
    });

    MCMove *move = [[MCMove alloc] init];
    move.queueIndex = queueIndex;
    move.slotIndex = slot;
    move.colorKey = _colorKeys[(NSUInteger)_basketColors[queueIndex]];
    move.capacity = _basketCaps[queueIndex];
    move.steps = steps;
    return move;
}

#pragma mark 求解

static const NSInteger MCSolverBudget = 120000;

- (NSInteger)hintQueueIndex {
    NSInteger pick = NSNotFound;
    NSInteger budget = MCSolverBudget;
    NSMutableSet<NSData *> *visited = [NSMutableSet set];
    if (MCSolvable(&_rules, _cells, _slots, _used, visited, &budget, &pick)) {
        return pick;
    }
    return NSNotFound;
}

- (MCSafety)safetyOfQueueIndex:(NSInteger)queueIndex {
    if (![self.selectableQueueIndexes containsObject:@(queueIndex)]) return MCSafetyFatal;
    const NSInteger slot = MCFirstFreeSlot(&_rules, _slots);
    if (slot == NSNotFound) return MCSafetyFatal;

    const size_t slotBytes = sizeof(MCSlotState) * (size_t)_rules.slotCount;
    int8_t *cells = (int8_t *)malloc((size_t)_rules.cellCount);
    memcpy(cells, _cells, (size_t)_rules.cellCount);
    MCSlotState *slots = (MCSlotState *)malloc(slotBytes);
    memcpy(slots, _slots, slotBytes);

    slots[slot].color = _basketColors[queueIndex];
    slots[slot].filled = 0;
    slots[slot].capacity = _basketCaps[queueIndex];
    MCSettle(&_rules, cells, slots, nil, nil);

    NSInteger budget = MCSolverBudget;
    NSMutableSet<NSData *> *visited = [NSMutableSet set];
    const BOOL safe = MCSolvable(&_rules, cells, slots,
                                 _used | (1ULL << queueIndex), visited, &budget, NULL);
    free(cells);
    free(slots);
    if (safe) return MCSafetyFine;
    // 没搜出解，但预算也见底了 —— 不能断言这一步就是死路
    return budget <= 0 ? MCSafetyUnknown : MCSafetyFatal;
}

@end
