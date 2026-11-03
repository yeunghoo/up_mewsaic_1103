#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
拆块猫玩法的关卡生成与验证工具。

规则（与客户端 MCBoard 一致）：
  1. 图案放在网格上，一个方块能被搬走的条件是：它的四邻中有一个空格，
     且该空格与图案外部连通（猫猫得能从外面走到它旁边）。
  2. 下方是一条有顺序的篮子队列，每个篮子有自己的颜色和自己的容量。
     同一种颜色可以有多个篮子，容量各不相同，这是主要的难度旋钮。
  3. 玩家只能点可见窗口内的篮子。篮子进槽后，所有在场篮子自动收走当前
     能搬的同色方块，搬走会暴露新方块，所以要循环结算到稳定。
  4. 篮子装满即离场腾出槽位，没装满就一直占着槽位等新方块暴露。
  5. 死局是槽位用尽且没有一个篮子还能收到方块。

关卡数据结构：
  grid   {(row, col): color}
  slots  [None | (color, filled, capacity)]
  queue  [(color, capacity), ...]   从左到右

用法：
  python3 blockcat.py melon      生成西瓜关卡
  python3 blockcat.py demo01     回归旧的 8x8 关卡
  python3 blockcat.py melon --replay   额外打印逐步解法
"""

from collections import deque
import json
import math
import os
import random
import sys

SLOTS = 3       # 上方槽位数
WINDOW = 3      # 下方能点的篮子数
PREVIEW = 3     # 窗口后面再露出几个供预判（只显示不能点）

NEIGHBORS = ((1, 0), (-1, 0), (0, 1), (0, -1))


# ---------------------------------------------------------------- 棋盘规则

def outside_air(grid, rows, cols):
    """从网格外围洪泛所有空格，返回与外部连通的空格集合。

    洪泛范围含一圈虚拟边界，保证外围连通。图案内部的封闭空腔洪泛不到，
    所以腔壁的方块搬不走。
    """
    start = (-1, -1)
    seen = {start}
    queue = deque([start])
    while queue:
        r, c = queue.popleft()
        for dr, dc in NEIGHBORS:
            nr, nc = r + dr, c + dc
            if not (-1 <= nr <= rows and -1 <= nc <= cols):
                continue
            if (nr, nc) in seen or (nr, nc) in grid:
                continue
            seen.add((nr, nc))
            queue.append((nr, nc))
    return seen


def collectible(grid, rows, cols):
    air = outside_air(grid, rows, cols)
    out = set()
    for (r, c) in grid:
        for dr, dc in NEIGHBORS:
            if (r + dr, c + dc) in air:
                out.add((r, c))
                break
    return out


def settle(grid, slots):
    """所有在场篮子自动收集，循环到稳定。原地修改 grid 与 slots。"""
    rows, cols = settle.rows, settle.cols
    log = []
    changed = True
    while changed:
        changed = False
        ready = collectible(grid, rows, cols)
        for i, slot in enumerate(slots):
            if slot is None:
                continue
            color, filled, cap = slot
            cands = sorted(p for p in ready if p in grid and grid[p] == color)
            took = []
            for p in cands:
                if filled + len(took) >= cap:
                    break
                del grid[p]
                took.append(p)
            if not took:
                continue
            changed = True
            filled += len(took)
            log.append(("take", i, color, took, filled))
            if filled >= cap:
                slots[i] = None
                log.append(("full", i, color, [], filled))
            else:
                slots[i] = (color, filled, cap)
    return log


def visible(queue, used):
    """可见窗口内、还没用过的篮子下标"""
    out = []
    for i in range(len(queue)):
        if used >> i & 1:
            continue
        out.append(i)
        if len(out) == WINDOW:
            break
    return out


def free_slot(slots):
    return next((i for i, s in enumerate(slots) if s is None), None)


def new_board(grid0):
    grid = dict(grid0)
    slots = [None] * SLOTS
    settle(grid, slots)
    return grid, slots


def peel_layers(grid, rows, cols):
    """反复剥掉当前能搬的一圈，用来看图案的深度结构"""
    work = dict(grid)
    layers = []
    while work:
        ring = collectible(work, rows, cols)
        if not ring:
            layers.append(("空腔", dict(work)))
            break
        layers.append((len(layers) + 1, {p: work[p] for p in ring}))
        for p in ring:
            del work[p]
    return layers


# ---------------------------------------------------------------- 图案生成

def make_melon(radius=7.0):
    """一片西瓜（圆形横切面）。

    颜色按到圆心的距离分带：外圈瓜皮、白圈、红肉。
    瓜皮做成放射状的深浅条纹 —— 真实西瓜皮就长这样，而且条纹是径向的，
    会横跨好几个剥离层，正好打破「颜色与层一一对应」那种毫无难度的结构。
    瓜籽排在两圈不同半径上，于是黑篮必然要等到不同深度才能装满。
    """
    size = int(round(radius * 2))
    center = (size - 1) / 2.0
    grid = {}
    for row in range(size):
        for col in range(size):
            dr = row - center
            dc = col - center
            dist = math.hypot(dr, dc)
            if dist > radius:
                continue
            t = dist / radius
            if t > 0.78:
                # 瓜皮：按角度切成 16 段，深浅绿交替
                angle = math.degrees(math.atan2(dr, dc)) % 360.0
                grid[(row, col)] = "DG" if int(angle / 22.5) % 2 == 0 else "LG"
            elif t > 0.70:
                grid[(row, col)] = "W"
            else:
                grid[(row, col)] = "R"

    # 瓜籽：两圈不同半径，角度错开
    for ring_t, count, offset in ((0.36, 7, 12.0), (0.58, 11, 0.0)):
        for k in range(count):
            a = math.radians(offset + 360.0 * k / count)
            p = (int(round(center + ring_t * radius * math.sin(a))),
                 int(round(center + ring_t * radius * math.cos(a))))
            if grid.get(p) == "R":
                grid[p] = "K"
    return grid, size, size


def make_demo01():
    """旧的 8x8 关卡，留作回归用"""
    pattern = ["OOOOOOOO", "WGGKKKKW", "WPYYYYPW", "WPBRRBPW",
               "WPBRRBPW", "GYRRRRYG", "GYYBBBBG", "GGKKKKPP"]
    grid = {}
    for r, line in enumerate(pattern):
        for c, ch in enumerate(line):
            if ch != ".":
                grid[(r, c)] = ch
    return grid, len(pattern), len(pattern[0])


# ---------------------------------------------------------------- 篮子容量

def split_capacity(total, parts, spread=2):
    """把某个颜色的方块总数拆成若干个容量递减的篮子。

    split_capacity(30, 3) -> [12, 10, 8]
    容量之和必须等于该色方块总数，否则最后一个篮子永远装不满、死占槽位。
    """
    base = (total + spread * parts * (parts - 1) / 2.0) / parts
    caps = [int(round(base - spread * i)) for i in range(parts)]
    caps[0] += total - sum(caps)
    if min(caps) < 2:
        raise ValueError("拆得太碎：%d 拆 %d 份得到 %s" % (total, parts, caps))
    return caps


def build_baskets(counts, plan, spread=2):
    """plan 形如 {'R': 4, 'DG': 2}，表示每种颜色分几个篮子"""
    baskets = []
    for color in sorted(counts):
        parts = plan.get(color, 1)
        for cap in split_capacity(counts[color], parts, spread):
            baskets.append((color, cap))
    return baskets


# ---------------------------------------------------------------- 队列排序

def find_order(grid0, baskets, rng=None, tension=True, node_limit=200000):
    """搜索一个篮子队列顺序，使玩家一路点队首就能通关。

    这保证了关卡可解：可见窗口一定包含队首，所以那条路径永远走得通。

    tension=True 时启发式是反着的 —— 优先试「当前装不满、会赖在槽位上」的
    篮子。顺滑的顺序谁都能过，只有让队列和图案的剥离顺序错开，玩家才会遇到
    「窗口里三个篮子都收不到东西」的局面。DFS 的回溯保证再怎么拧巴也仍可解。
    """
    count = len(baskets)
    rows, cols = settle.rows, settle.cols
    rng = rng or random.Random(0)
    nodes = [0]

    def dfs(grid, slots, used, order):
        if not grid:
            return list(order)
        nodes[0] += 1
        if nodes[0] > node_limit:
            return None
        slot = free_slot(slots)
        if slot is None:
            return None  # 槽位用尽而结算已稳定，这条路死了

        ready = collectible(grid, rows, cols)
        avail = {}
        for p in ready:
            avail[grid[p]] = avail.get(grid[p], 0) + 1

        def fills(i):
            return 1 if avail.get(baskets[i][0], 0) >= baskets[i][1] else 0

        cands = [i for i in range(count) if not (used >> i & 1)]
        cands.sort(key=lambda i: (fills(i) if tension else 1 - fills(i), rng.random()))
        for i in cands:
            ng, ns = dict(grid), list(slots)
            ns[slot] = (baskets[i][0], 0, baskets[i][1])
            settle(ng, ns)
            found = dfs(ng, ns, used | (1 << i), order + [i])
            if found:
                return found
        return None

    grid, slots = new_board(grid0)
    return dfs(grid, slots, 0, [])


def search_queue(grid0, baskets, rounds=24, target_hi=0.45, trials=200):
    """跑多轮带随机的搜索，挑一个「可解但容易走错」的队列。

    难度看的是带噪真人的失败率，不能用纯贪心：贪心是确定性的，几百局跑的是
    同一条路，失败率恒为 0% 或 100%，拿它当评分等于没评。

    评分同时看三件事：
      失败率  越高越难，但超过 target_hi 就反过来扣分 —— 步步是死局的队列
              玩家只能靠猜，那不叫难度。
      峰值占槽 越接近满槽越好，全程贴着上限走才有紧张感。
      空转    上了篮子却一块都收不到的步数，太多说明队列和图案脱节，玩家
              会觉得莫名其妙，扣分。
    """
    best = None
    for seed in range(rounds):
        rng = random.Random(seed * 7919 + 13)
        order = find_order(grid0, baskets, rng=rng, tension=True)
        if not order:
            continue
        queue = [baskets[i] for i in order]
        stats = monte_carlo(grid0, queue, trials=trials, seed=seed, names=("noisy",))
        steps, _ = replay(grid0, queue, list(range(len(queue))))
        fail = stats["noisy"]["fail_rate"]
        fail_score = fail if fail <= target_hi else max(0.0, 2 * target_hi - fail)
        idle = sum(1 for s in steps
                   if len(s) > 4 and not any(e[0] == "take" for e in s[2]))
        peak = max(s[4] for s in steps if len(s) > 4)
        score = fail_score + 0.06 * peak - 0.04 * idle
        if best is None or score > best[0]:
            best = (score, queue)
    if not best:
        return None
    # 选定之后再把三种玩家都跑一遍，用于报告
    return (best[1], monte_carlo(grid0, best[1], trials=600))


# ---------------------------------------------------------------- 难度评估

def replay(grid0, queue, picks):
    """按给定顺序走一遍，返回逐步日志"""
    grid, slots = new_board(grid0)
    used = 0
    steps = []
    for pick in picks:
        slot = free_slot(slots)
        if slot is None or pick not in visible(queue, used):
            steps.append(("blocked", pick, None, len(grid)))
            break
        slots[slot] = (queue[pick][0], 0, queue[pick][1])
        used |= 1 << pick
        # 峰值要在结算之前数：结算会让装满的篮子立刻离场
        peak = sum(1 for s in slots if s is not None)
        log = settle(grid, slots)
        steps.append((queue[pick], slot, log, len(grid), peak))
    return steps, len(grid)


def play_policy(grid0, queue, choose, rng):
    """用给定策略玩一局，返回 (是否通关, 峰值占槽, 步数)"""
    grid, slots = new_board(grid0)
    used = 0
    peak = 0
    moves = 0
    while grid:
        slot = free_slot(slots)
        options = visible(queue, used)
        if slot is None or not options:
            return False, peak, moves
        rows, cols = settle.rows, settle.cols
        ready = collectible(grid, rows, cols)
        avail = {}
        for p in ready:
            avail[grid[p]] = avail.get(grid[p], 0) + 1
        pick = choose(options, queue, avail, rng)
        slots[slot] = (queue[pick][0], 0, queue[pick][1])
        used |= 1 << pick
        moves += 1
        peak = max(peak, sum(1 for s in slots if s is not None))
        settle(grid, slots)
    return True, peak, moves


def choose_random(options, queue, avail, rng):
    return rng.choice(options)


def choose_greedy(options, queue, avail, rng):
    """挑当前能收到最多方块的篮子"""
    return max(options, key=lambda i: (min(avail.get(queue[i][0], 0), queue[i][1]),
                                       -queue[i][1]))


def choose_noisy(options, queue, avail, rng):
    """像个真人：多数时候按上面那套算，但隔一会儿会看走眼。

    纯贪心是确定性的，几百局跑的是同一条路，失败率只会是 0% 或 100%，
    那是「这一个策略能不能过」的判断题，不是难度。加一点噪声才量得出
    「容不容易走错」，这个数字也才和真人体验对得上。
    """
    if rng.random() < 0.15:
        return rng.choice(options)
    return choose_greedy(options, queue, avail, rng)


POLICIES = {"random": choose_random, "greedy": choose_greedy, "noisy": choose_noisy}


def monte_carlo(grid0, queue, trials=300, seed=20260922, names=None):
    """几种模拟玩家的失败率。关卡本身一定可解，这里量的是「有多容易走错」。"""
    out = {}
    for name in (names or ("random", "greedy", "noisy")):
        policy = POLICIES[name]
        rng = random.Random(seed)
        wins = 0
        peaks = []
        for _ in range(trials):
            ok, peak, _ = play_policy(grid0, queue, policy, rng)
            wins += 1 if ok else 0
            peaks.append(peak)
        out[name] = {
            "fail_rate": 1.0 - wins / trials,
            "avg_peak": sum(peaks) / len(peaks),
        }
    return out


# ---------------------------------------------------------------- 输出

def render(grid, rows, cols, width=2):
    ready = collectible(grid, rows, cols)
    lines = []
    for r in range(rows):
        cells = []
        for c in range(cols):
            ch = grid.get((r, c))
            if ch is None:
                cells.append("·".rjust(width))
            elif (r, c) in ready:
                cells.append(ch.rjust(width))
            else:
                cells.append(ch.lower().rjust(width))
        lines.append(" ".join(cells))
    return "\n".join(lines)


def to_pattern(grid, rows, cols, keys):
    """把 grid 转成每格一个字符的文本行，多字符色名映射成单字符"""
    lines = []
    for r in range(rows):
        line = ""
        for c in range(cols):
            color = grid.get((r, c))
            line += keys[color] if color else "."
        lines.append(line)
    return lines


LEVELS = {
    "melon": {
        "id": "melon-01",
        "build": lambda: make_melon(7.0),
        # 每种颜色分几个篮子，容量由 split_capacity 递减拆分。
        # 拆得细是为了让篮子总数远多于可见窗口：窗口只能看到队列的一小截，
        # 玩家没法未卜先知，才会撞上「三个候选都收不到东西」的局面。
        "plan": {"R": 6, "DG": 4, "LG": 4, "W": 2, "K": 3},
        "spread": 2,
        "chars": {"DG": "G", "LG": "L", "W": "W", "R": "R", "K": "K"},
        "names": {"DG": "深绿", "LG": "浅绿", "W": "白", "R": "红", "K": "黑"},
    },
    "demo01": {
        "id": "demo-01",
        "build": make_demo01,
        "plan": {"O": 1, "W": 1, "G": 1, "K": 1, "P": 1, "R": 1, "Y": 1, "B": 1},
        "spread": 0,
        "chars": {k: k for k in "OWGKPRYB"},
        "names": {"O": "橙", "W": "白", "G": "灰", "K": "黑",
                  "P": "粉", "R": "红", "Y": "黄", "B": "蓝"},
    },
}


def generate(name, show_replay=False):
    spec = LEVELS[name]
    grid0, rows, cols = spec["build"]()
    settle.rows, settle.cols = rows, cols

    counts = {}
    for color in grid0.values():
        counts[color] = counts.get(color, 0) + 1

    print("=" * 72)
    print("关卡 %s   网格 %dx%d   方块 %d 个   颜色 %d 种"
          % (spec["id"], rows, cols, len(grid0), len(counts)))
    print("=" * 72)
    print(render(grid0, rows, cols))
    print()
    print("大写 = 现在就能搬，小写 = 猫猫走不到\n")

    baskets = build_baskets(counts, spec["plan"], spec["spread"])
    print("--- 篮子配置（同色多篮、容量递减）---")
    for color in sorted(counts):
        caps = [cap for c, cap in baskets if c == color]
        print("  %-4s %-3s %3d 个方块  ->  %d 个篮子 容量 %s  合计 %d"
              % (color, spec["names"][color], counts[color], len(caps),
                 caps, sum(caps)))
        assert sum(caps) == counts[color]
    print("  篮子总数 %d，槽位 %d，可点 %d 个，另外预览 %d 个"
          % (len(baskets), SLOTS, WINDOW, PREVIEW))
    print()

    print("--- 剥离层次 ---")
    for tag, cells in peel_layers(grid0, rows, cols):
        per = {}
        for color in cells.values():
            per[color] = per.get(color, 0) + 1
        desc = "  ".join("%s x%d" % (k, v) for k, v in sorted(per.items()))
        print("  第 %-3s 层 %3d 格   %s" % (tag, len(cells), desc))
    print()

    print("--- 搜索篮子顺序（要可解，又要容易走错）---")
    best = search_queue(grid0, baskets)
    if not best:
        print("  没找到可行顺序，需要调整容量配置")
        return None
    queue, stats = best
    print("  队列：%s" % "  ".join("%s%d" % (c, cap) for c, cap in queue))
    print()

    steps, left = replay(grid0, queue, list(range(len(queue))))
    print("  一路点队首可以通关：%d 步，剩余 %d 块" % (len(steps), left))
    peak = max(s[4] for s in steps if len(s) > 4)
    print("  这条保底解法的峰值占槽 %d / %d" % (peak, SLOTS))

    print()
    print("--- 难度评估（关卡一定可解，这里量的是有多容易走错）---")
    print("  带噪真人   失败率 %5.1f%%   平均峰值占槽 %.2f   <- 主要看这个"
          % (stats["noisy"]["fail_rate"] * 100, stats["noisy"]["avg_peak"]))
    print("  纯贪心     失败率 %5.1f%%   （确定性策略，只说明这一条路通不通）"
          % (stats["greedy"]["fail_rate"] * 100))
    print("  乱点玩家   失败率 %5.1f%%   （难度上界）"
          % (stats["random"]["fail_rate"] * 100))

    if show_replay:
        print()
        print("--- 逐步解法 ---")
        grid, slots = new_board(grid0)
        used = 0
        for step, pick in enumerate(range(len(queue)), 1):
            slot = free_slot(slots)
            slots[slot] = (queue[pick][0], 0, queue[pick][1])
            used |= 1 << pick
            log = settle(grid, slots)
            taken = sum(len(entry[3]) for entry in log if entry[0] == "take")
            fulls = sum(1 for entry in log if entry[0] == "full")
            state = " | ".join("空" if s is None else "%s %d/%d" % (s[0], s[1], s[2])
                               for s in slots)
            print("  第 %2d 步  上 %s%d  搬走 %2d 块  %d 个篮子装满   槽位 [%s]  剩余 %d"
                  % (step, queue[pick][0], queue[pick][1], taken, fulls, state, len(grid)))

    chars = spec["chars"]

    # 逐步轨迹，给 tools/kerneltest 拿去和 Objective-C 内核对账。
    # 手抄这些数字太容易抄错，让生成器直接吐出来。
    trace = []
    tgrid, tslots = new_board(grid0)
    trace.append({"remaining": len(tgrid),
                  "collectible": len(collectible(tgrid, rows, cols))})
    for pick in range(len(queue)):
        slot = free_slot(tslots)
        tslots[slot] = (queue[pick][0], 0, queue[pick][1])
        settle(tgrid, tslots)
        trace.append({
            "pick": pick,
            "color": chars[queue[pick][0]],
            "capacity": queue[pick][1],
            "remaining": len(tgrid),
            "collectible": len(collectible(tgrid, rows, cols)),
            "slots": [None if s is None
                      else {"color": chars[s[0]], "filled": s[1], "capacity": s[2]}
                      for s in tslots],
        })

    out = {
        "id": spec["id"],
        "grid": {"rows": rows, "cols": cols,
                 "pattern": to_pattern(grid0, rows, cols, chars)},
        "slots": SLOTS,
        "window": WINDOW,
        "preview": PREVIEW,
        "baskets": [{"color": chars[c], "capacity": cap} for c, cap in queue],
        "basketsCompact": " ".join("%s%d" % (chars[c], cap) for c, cap in queue),
        "trace": trace,
        "meta": {
            "blocks": len(grid0),
            "colors": {chars[c]: n for c, n in counts.items()},
            "peakSlotUsage": peak,
            "solutionSteps": len(queue),
            "noisyFailRate": round(stats["noisy"]["fail_rate"], 4),
            "randomFailRate": round(stats["random"]["fail_rate"], 4),
            "greedyFailRate": round(stats["greedy"]["fail_rate"], 4),
        },
    }
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "level_%s.json" % spec["id"])
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print("\n关卡已写出：%s" % path)
    return out


if __name__ == "__main__":
    which = "melon"
    for arg in sys.argv[1:]:
        if arg in LEVELS:
            which = arg
    generate(which, show_replay="--replay" in sys.argv)
