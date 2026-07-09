# 《仙途·墨渊》

> 2D 俯视角动作 Roguelike · 水墨五行构筑
> Godot 4.2 项目 · GDScript

<p align="center">
  <em>落墨即杀 · 五行随心 · 每一局都是独特修行 · 留白之境</em>
</p>

---

## 项目简介

《仙途·墨渊》是一款以中国水墨风为视觉基调的 2D 俯视角动作 Roguelike。玩家扮演修仙者，在 5×6 迷宫中探索、战斗、构筑五行 build，挑战层 Boss，层层推进直至仙途尽头。

核心玩法围绕**五行反应系统**展开——通过遗物组合触发 14 种反应配方，再借助五行盘邻接拓扑放大效果，形成"低门槛触发、高天花板追极致"的双层构筑体验。

## 四大设计支柱

| 支柱 | 内涵 | 落地锚点 |
|---|---|---|
| **落墨即杀** | 打击感是生命线，单次命中必须有"重量" | 顿帧 / 震屏 / 水墨粒子 / 三段连击 / 瞬移闪避无敌帧 |
| **五行随心** | 五行反应是构筑核心，"我安排的局" | 混合方案：触发用集合，放大用五行盘邻接 |
| **每一局都是独特修行** | Roguelike 随机构筑，每局 build 不同 | 反应配方扩展框架 + 角色多条 build 路径 + 遗物组合 |
| **留白之境** | 信息清晰不堆砌，水墨留白哲学 | 探索式地图 + UI 化解认知负荷 + 内容量宁缺毋滥 |

## 当前开发状态

### ✅ P0 核心层（已完成）

可玩打击感原型，项目已可运行。

| 系统 | 实现内容 | 核心文件 |
|---|---|---|
| 迷宫生成 | 5×6 网格 + BFS 通路验证 + 分支取舍 | [labyrinth_gen.gd](scripts/world/labyrinth_gen.gd) |
| 玩家角色 | 燕无归：三段连击 + 瞬移闪避 + 第三段突进 | [player_yan.gd](scripts/player/player_yan.gd) |
| 五行系统 | 五行盘 Path B 邻接加成（相生 ×1.5 / 相克 ×0.5） | [wuxing_board.gd](scripts/wuxing/wuxing_board.gd) |
| 反应系统 | 14 种反应配方 + Path B 放大 + 增量 buff 更新 | [reaction_system.gd](scripts/wuxing/reaction_system.gd) |
| 遗物系统 | 14 件遗物 · 4 稀有度（白/蓝/紫/金） | [relic_db.gd](scripts/relics/relic_db.gd) |
| 货币系统 | 三层货币：灵气（层内）/ 灵石（层间）/ 业力（永久） | [game_state.gd](scripts/autoload/game_state.gd) |
| 打击感 | Hit Stop（墙钟时间）+ 震屏 + 事件总线解耦 | [hit_feel_manager.gd](scripts/combat/hit_feel_manager.gd) |
| 战斗事件 | 信号总线：命中 / 受伤 / 暴击 / 闪避 / 击杀 | [combat_events.gd](scripts/combat/combat_events.gd) |
| 商店数据层 | 灵气/灵石/业力三栏商品 + 递增定价 | [shop_system.gd](scripts/world/shop_system.gd) |
| 敌人基类 | HP / 伤害 / AI 巡逻追击 / 受击击退 / 死亡掉落 | [enemy_base.gd](scripts/enemy/enemy_base.gd) |

### 🚧 P1 扩展层（计划中）

完整核心循环，验证支柱二/三。

- 四角色全集（云清子·远程弹幕 / 墨尘·召唤流 / 慕容清霜·阵法领域）
- 25 种敌人（5 区域 × 5 种）+ 5 个 Boss
- 40 件遗物（14 通用 + 16 角色专属 + 10 配方遗物）
- 20 种事件房
- 商店 UI + 层间结算屏
- 5 层区域主题 + 业力基础

### 🔮 P2 / Meta 深度层（远期）

- 异化能力 + 祖物传承 + 黑市/祭坛
- 业力养成树（7 主分支 + 2 收集分支）
- 6 稀有度（+红/黑）+ 反应配方 mod 式扩展

## 核心系统架构

```
Autoload 初始化顺序（project.godot）
─────────────────────────────────────
GameState        三层货币 + 属性聚合
    ↓
RelicDB          14 件遗物元数据
    ↓
WuxingBoard      五行盘拓扑（先于 ReactionSystem）
    ↓
ReactionSystem   监听 board_changed，自动重算反应
    ↓
CombatEvents     信号总线（命中/受伤/暴击/闪避/击杀）
```

**战斗命中链路**：
```
玩家 Hitbox → 敌人 Hurtbox (area_entered)
    → CombatEvents.trigger_hit()        # 发命中信号
        → HitFeelManager._on_hit()     # 顿帧 + 震屏
    → enemy.take_damage()               # 伤害结算
        → enemy._die() → GameState.add_qi() / add_spirit_stone()
```

## 运行方式

### 环境要求
- Godot 4.2+（已在 Godot 4.7 stable 验证）

### 启动
1. 用 Godot 打开项目目录
2. 直接运行主场景 `res://scenes/main.tscn`

### 操作
| 操作 | 按键 |
|---|---|
| 移动 | WASD / 方向键 |
| 攻击（三段连击） | 鼠标左键 / J |
| 瞬移闪避 | 空格 / K |
| 交互 | E |

## 项目结构

```
rouglike-doubao/
├── project.godot              # Godot 项目配置
├── scenes/                    # 场景文件
│   ├── main.tscn              # 主场景入口
│   ├── player_yan.tscn        # 燕无归角色场景
│   └── enemy_base.tscn        # 敌人基类场景
├── scripts/
│   ├── autoload/              # Autoload 单例
│   │   ├── game_state.gd      # 货币 + 属性聚合
│   │   └── main.gd            # 主场景脚本
│   ├── player/                # 玩家角色
│   ├── enemy/                 # 敌人
│   ├── combat/                # 战斗系统
│   │   ├── combat_events.gd   # 信号总线
│   │   └── hit_feel_manager.gd # 打击感
│   ├── wuxing/                # 五行系统
│   │   ├── wuxing_board.gd    # 五行盘拓扑
│   │   └── reaction_system.gd # 反应配方
│   ├── relics/                # 遗物
│   │   └── relic_db.gd        # 遗物数据库
│   └── world/                 # 世界系统
│       ├── labyrinth_gen.gd   # 迷宫生成
│       └── shop_system.gd     # 商店
└── 文档材料/
    └── 仙途墨渊-设计文档-v3.0.md  # 完备设计文档（970 行）
```

## 设计文档

完整设计文档见 [仙途墨渊-设计文档-v3.0.md](文档材料/仙途墨渊-设计文档-v3.0.md)，包含 19 个章节 + 6 个附录，覆盖：

- §1-3：设计支柱、核心循环、分层路线图
- §4-15：核心系统规格（迷宫、战斗、反应、五行盘、角色、敌人、遗物、经济、商店、养成、事件、结算屏）
- §16-19：Meta 愿景（异化、祖物、黑市、业力树）
- 附录 F：代码现状对齐表

## 版本管理

- 主分支：`master`
- 开发分支：建议 `p1-development` 等，按阶段命名

---

<p align="center">
  <em>仙途漫漫，墨渊无垠。</em>
</p>
