//
//  main.m
//  规则内核对照测试
//
//  把 MCBoard 的行为和 tools/levelgen/blockcat.py 的输出逐步比对，
//  确认客户端内核与关卡生成器用的是同一套规则。
//
//  对照数据直接读生成器写出的 level_melon-01.json，不手抄数字：
//  关卡一改，这里跟着改，抄漏一个数就会被测出来。
//
//  编译运行：
//    cd tools/kerneltest && ./run.sh
//

#import <Foundation/Foundation.h>
#import "MCLevel.h"
#import "MCBoard.h"

static NSInteger gFailures = 0;
static NSInteger gChecks = 0;

static void Check(BOOL condition, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    gChecks++;
    if (condition) {
        printf("  [ok]   %s\n", message.UTF8String);
    } else {
        printf("  [FAIL] %s\n", message.UTF8String);
        gFailures++;
    }
}

/// 把棋盘画出来，大写表示能搬，小写表示猫猫走不到
static void DumpBoard(MCBoard *board) {
    NSSet<NSNumber *> *ready = [board collectibleIndexes];
    for (NSInteger row = 0; row < board.level.rows; row++) {
        NSMutableString *line = [NSMutableString stringWithString:@"    "];
        for (NSInteger col = 0; col < board.level.cols; col++) {
            const NSInteger index = row * board.level.cols + col;
            NSString *key = [board colorKeyAtIndex:index];
            if (!key) {
                [line appendString:@" ."];
            } else if ([ready containsObject:@(index)]) {
                [line appendFormat:@" %@", key.uppercaseString];
            } else {
                [line appendFormat:@" %@", key.lowercaseString];
            }
        }
        printf("%s\n", line.UTF8String);
    }
}

static NSString *SlotsDescription(MCBoard *board) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (id entry in board.slots) {
        if (entry == [NSNull null]) {
            [parts addObject:@"空"];
        } else {
            MCBasket *basket = entry;
            [parts addObject:[NSString stringWithFormat:@"%@ %ld/%ld", basket.colorKey,
                              (long)basket.filled, (long)basket.capacity]];
        }
    }
    return [parts componentsJoinedByString:@" | "];
}

static NSString *SlotsDescriptionFromTrace(NSArray *slots) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (id entry in slots) {
        if (entry == [NSNull null]) {
            [parts addObject:@"空"];
        } else {
            NSDictionary *slot = entry;
            [parts addObject:[NSString stringWithFormat:@"%@ %ld/%ld", slot[@"color"],
                              (long)[slot[@"filled"] integerValue],
                              (long)[slot[@"capacity"] integerValue]]];
        }
    }
    return [parts componentsJoinedByString:@" | "];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *fixturePath = argc > 1 ? @(argv[1]) : @"../levelgen/level_melon-01.json";
        NSData *data = [NSData dataWithContentsOfFile:fixturePath];
        if (!data) {
            printf("读不到生成器的输出：%s\n", fixturePath.UTF8String);
            return 2;
        }
        NSDictionary *fixture = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

        MCLevel *level = [MCLevel demoLevel];
        printf("\n=== 关卡 %s ===\n", level.levelId.UTF8String);
        printf("网格 %ldx%ld  槽位 %ld  可点 %ld  预览 %ld  篮子 %lu 个\n\n",
               (long)level.rows, (long)level.cols, (long)level.slotCount,
               (long)level.windowSize, (long)level.previewSize,
               (unsigned long)level.baskets.count);

        printf("--- 关卡数据和生成器一致 ---\n");
        Check([level.levelId isEqualToString:fixture[@"id"]],
              @"关卡 id 是 %@", level.levelId);
        NSString *compact = [[level.baskets valueForKey:@"description"]
                             componentsJoinedByString:@" "];
        Check([compact isEqualToString:fixture[@"basketsCompact"]],
              @"篮子队列和生成器一致：%@", compact);
        Check([level.pattern isEqualToArray:fixture[@"grid"][@"pattern"]],
              @"图案和生成器一致（%ld 行）", (long)level.rows);

        // 每个颜色的篮子容量之和必须等于图案里这一色的方块总数，
        // 少一个就有篮子永远装不满、死占槽位，多一个就是队列末尾有篮子用不上
        NSMutableDictionary<NSString *, NSNumber *> *capacityByColor = [NSMutableDictionary dictionary];
        for (MCBasketSpec *spec in level.baskets) {
            capacityByColor[spec.colorKey] =
                @(capacityByColor[spec.colorKey].integerValue + spec.capacity);
        }
        NSDictionary<NSString *, NSNumber *> *blocksByColor = fixture[@"meta"][@"colors"];
        for (NSString *color in blocksByColor) {
            Check(capacityByColor[color].integerValue == blocksByColor[color].integerValue,
                  @"%@ 色：%ld 个方块，篮子容量合计 %ld",
                  color, (long)blocksByColor[color].integerValue,
                  (long)capacityByColor[color].integerValue);
        }

        MCBoard *board = [[MCBoard alloc] initWithLevel:level];
        printf("\n开局棋盘：\n");
        DumpBoard(board);

        NSArray<NSDictionary *> *trace = fixture[@"trace"];
        printf("\n--- 开局校验 ---\n");
        Check(board.remainingBlockCount == [trace[0][@"remaining"] integerValue],
              @"方块总数 %ld", (long)board.remainingBlockCount);
        Check((NSInteger)[board collectibleIndexes].count ==
              [trace[0][@"collectible"] integerValue],
              @"开局能搬 %lu 块，生成器第 1 层也是 %ld 格",
              (unsigned long)[board collectibleIndexes].count,
              (long)[trace[0][@"collectible"] integerValue]);
        Check((NSInteger)board.selectableQueueIndexes.count == level.windowSize,
              @"可点篮子 %lu 个", (unsigned long)board.selectableQueueIndexes.count);
        Check((NSInteger)board.visibleQueueIndexes.count ==
              level.windowSize + level.previewSize,
              @"下方一共露出 %lu 个篮子（能点的加预览的）",
              (unsigned long)board.visibleQueueIndexes.count);
        Check(!board.isWin && !board.isDeadlock, @"开局既没通关也没死局");

        // 生成器保证：一路点队首必定通关。逐步核对剩余块数、能搬的块数、槽位状态。
        printf("\n--- 一路点队首，逐步对照生成器 ---\n");
        for (NSUInteger step = 1; step < trace.count; step++) {
            NSDictionary *expected = trace[step];
            NSArray<NSNumber *> *options = board.selectableQueueIndexes;
            if (options.count == 0) {
                Check(NO, @"第 %lu 步没有可点的篮子了", (unsigned long)step);
                break;
            }
            const NSInteger pick = options.firstObject.integerValue;
            MCBasketSpec *spec = level.baskets[(NSUInteger)pick];
            MCMove *move = [board playBasketAtQueueIndex:pick];
            if (!move) {
                Check(NO, @"第 %lu 步点 %@ 被拒绝了", (unsigned long)step, spec);
                break;
            }

            NSInteger taken = 0, full = 0;
            for (MCStep *s in move.steps) {
                if (s.kind == MCStepKindTake) taken += (NSInteger)s.indexes.count;
                else full++;
            }

            const BOOL remainingOK =
                board.remainingBlockCount == [expected[@"remaining"] integerValue];
            const BOOL collectibleOK = (NSInteger)[board collectibleIndexes].count ==
                [expected[@"collectible"] integerValue];
            NSString *slotsNow = SlotsDescription(board);
            NSString *slotsExpected = SlotsDescriptionFromTrace(expected[@"slots"]);
            const BOOL slotsOK = [slotsNow isEqualToString:slotsExpected];

            Check(remainingOK && collectibleOK && slotsOK,
                  @"第 %2lu 步 上 %@  搬走 %2ld 块  %ld 个篮子装满  剩余 %ld  槽位 [%@]",
                  (unsigned long)step, spec, (long)taken, (long)full,
                  (long)board.remainingBlockCount, slotsNow);
            if (!remainingOK) {
                printf("         剩余对不上，生成器是 %ld\n",
                       (long)[expected[@"remaining"] integerValue]);
            }
            if (!collectibleOK) {
                printf("         能搬的块数对不上：内核 %lu，生成器 %ld\n",
                       (unsigned long)[board collectibleIndexes].count,
                       (long)[expected[@"collectible"] integerValue]);
            }
            if (!slotsOK) {
                printf("         槽位对不上，生成器是 [%s]\n", slotsExpected.UTF8String);
            }
        }

        Check(board.isWin, @"走完队列通关，棋盘清空");

        // 每个篮子容量不同，装满就该立刻离场；上面逐步核对的槽位状态已经覆盖了
        // 这一点，这里再确认收尾时槽位确实都空了
        Check([SlotsDescription(board) isEqualToString:@"空 | 空 | 空"],
              @"通关时三个槽位都腾空了");

        printf("\n--- 可见窗口随消耗前移 ---\n");
        [board reset];
        Check(board.remainingBlockCount == [trace[0][@"remaining"] integerValue],
              @"reset 之后回到 %ld 块", (long)board.remainingBlockCount);
        NSArray<NSNumber *> *before = board.visibleQueueIndexes;
        [board playBasketAtQueueIndex:before.firstObject.integerValue];
        NSArray<NSNumber *> *after = board.visibleQueueIndexes;
        Check(![after containsObject:before.firstObject],
              @"用掉的篮子不再露出来");
        Check(after.count == before.count &&
              [after.lastObject integerValue] == [before.lastObject integerValue] + 1,
              @"后面的篮子补上来一个：%@ -> %@", before, after);

        printf("\n--- 求解器 ---\n");
        [board reset];
        const NSInteger hint = [board hintQueueIndex];
        Check(hint != NSNotFound, @"开局能给出提示");
        if (hint != NSNotFound) {
            printf("  开局提示点 %s\n",
                   [level.baskets[(NSUInteger)hint] description].UTF8String);
        }
        // 关卡一大，求解器可能在预算内搜不完。搜不完要如实报 Unknown，
        // 绝不能把没搜完当成死路，否则界面会把能走的路标成危险。
        NSMutableArray<NSString *> *verdicts = [NSMutableArray array];
        for (NSNumber *option in board.selectableQueueIndexes) {
            const MCSafety safety = [board safetyOfQueueIndex:option.integerValue];
            NSString *word = safety == MCSafetyFine ? @"安全"
                           : safety == MCSafetyFatal ? @"死路" : @"未知";
            [verdicts addObject:[NSString stringWithFormat:@"%@=%@",
                                 level.baskets[(NSUInteger)option.integerValue], word]];
            Check(safety != MCSafetyFatal || option.integerValue != hint,
                  @"提示给出的选择不会被判成死路");
        }
        printf("  开局三个选择：%s\n",
               [verdicts componentsJoinedByString:@"  "].UTF8String);

        printf("\n=== %ld 项检查，%s ===\n\n", (long)gChecks,
               gFailures == 0 ? "全部通过" : "有失败项");
        return gFailures == 0 ? 0 : 1;
    }
}
