#!/bin/bash
# 编译并运行规则内核的对照测试。
# MCLevel / MCBoard 只依赖 Foundation，所以可以直接在 mac 上跑，不用起模拟器。
set -e

cd "$(dirname "$0")"
GAME_DIR="../../loop_miao/Game"

clang -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter \
    -framework Foundation \
    -I "$GAME_DIR" \
    "$GAME_DIR/MCLevel.m" \
    "$GAME_DIR/MCBoard.m" \
    main.m \
    -o kerneltest

./kerneltest
