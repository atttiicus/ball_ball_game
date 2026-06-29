## Autoload: GameConfig
## 游戏所有关键参数的集中管理，修改此文件即可调整游戏平衡性
extends Node

# ── 世界地图 ──────────────────────────────────────────
const WORLD_SIZE     := Vector2(4000.0, 4000.0)
const WALL_THICKNESS := 50.0

# ── 球基础参数 ────────────────────────────────────────
const BALL_MIN_RADIUS    := 15.0   # 球的最小半径（质量下限对应）
const BALL_MAX_RADIUS    := 2000.0  # 球的最大半径（质量上限对应）
const EAT_RATIO          := 1.1    # 吞噬阈值：质量达到对方 1.1 倍才能吃掉

# 速度公式：speed = SPEED_MULT / radius，半径越小越快
const SPEED_MULT := 4000.0
const SPEED_MIN  := 70.0
const SPEED_MAX  := 280.0

# ── 玩家参数 ──────────────────────────────────────────
const PLAYER_SPAWN_RADIUS        := 20.0   # 出生时的初始半径
const PLAYER_SPLIT_LAUNCH_SPEED  := 500.0  # 分裂时新球的飞出速度
const PLAYER_SPLIT_LAUNCH_DECEL  := 3.5    # 飞出惯性衰减系数
const PLAYER_MIN_SPLIT_RADIUS    := 25.0   # 允许分裂的最小半径
const PLAYER_MERGE_DELAY         := 3.0   # 分裂后多少秒可以合并（秒）
const PLAYER_MAX_CELLS           := 32      # 同时存在的最大分裂块数
const PLAYER_SPAWN_INVINCIBLE_TIME := 300.0  # 出生保护时长（秒）

# ── AI 参数 ───────────────────────────────────────────
const AI_COUNT               := 20     # 场上维持的 AI 球数量
const AI_STATE_INTERVAL      := 0.4    # AI 决策间隔（秒）
const AI_MIN_SPLIT_RADIUS    := 28.0   # AI 允许分裂的最小半径
const AI_MERGE_DELAY         := 12.0   # AI 分裂后的合并冷却时间（秒）
const AI_SPLIT_LAUNCH_SPEED  := 380.0  # AI 分裂时飞出速度
const AI_SPLIT_LAUNCH_DECEL  := 3.5    # AI 飞出惯性衰减
const AI_FLEE_SPLIT_TIME     := 2.5    # 逃跑超过此时间触发分裂（秒）
const AI_HUNT_SPLIT_TIME     := 5.5    # 追逐超过此时间触发分裂（秒）

# ── 食物参数 ──────────────────────────────────────────
const FOOD_MAX_COUNT     := 500    # 场上食物上限
const FOOD_SPAWN_BATCH   := 20     # 每次补充食物数量
const FOOD_SPAWN_INTERVAL := 0.5   # 食物补充间隔（秒）
const FOOD_RADIUS        := 6.0    # 食物半径

# ── 炸弹参数 ──────────────────────────────────────────
const BOMB_COUNT        := 8       # 场上炸弹数量
const BOMB_RADIUS       := 14.0    # 炸弹碰撞半径
const BOMB_RESPAWN_TIME := 18.0    # 炸弹触发后重生时间（秒）

# ── 摄像机参数 ────────────────────────────────────────
const CAM_ZOOM_MIN           := 0.25   # 最大缩放比（最远）
const CAM_ZOOM_MAX           := 1.2    # 最小缩放比（最近）
const CAM_RADIUS_FOR_MIN_ZOOM := 250.0 # 球半径达到此值时缩到最远
const CAM_RADIUS_FOR_MAX_ZOOM := 20.0  # 球半径为此值时使用最近缩放
const CAM_ZOOM_SMOOTH        := 3.0    # 缩放插值速度
const CAM_FOLLOW_SMOOTH      := 8.0    # 位置跟随速度
const CAM_MULTI_PADDING      := 150.0  # 多目标模式视野边距
