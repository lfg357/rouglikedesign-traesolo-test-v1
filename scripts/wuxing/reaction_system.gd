extends Node
## 反应层系统
## 玩家每装备/移除一件遗物，重新 evaluate 所有反应配方
## 4 类判定规则：tag_count / element_pair / element_all / earth_anchor
## Path B 加成：元素反应的效果受五行盘邻接乘数放大

# ─── 反应配方库 ───
var reactions: Array = []

# 当前激活的反应
var active_reactions: Array = []

# 当前装备遗物缓存（由遗物管理系统调用 set_equipped_relics 更新）
var equipped_relics: Array = []

signal reactions_changed(active_list: Array)

func _ready() -> void:
    _init_reactions()
    # 监听棋盘变化
    WuxingBoard.board_changed.connect(_on_board_changed)

# ─── 初始化 14 种反应 ───
func _init_reactions() -> void:
    # === 流派堆叠（tag_count）===
    reactions.append({
        "id": "sword_intent",
        "name": "剑意汇聚",
        "type": "tag_count",
        "tag": "sword_intent",
        "min": 3,
        "tier": "gold",
        "desc": "攻击 +30%，三连追加剑意斩",
        "stats": {"damage_mul": 0.30}
    })
    reactions.append({
        "id": "blood_rage",
        "name": "血怒共鸣",
        "type": "tag_count",
        "tag": "blood_rage",
        "min": 2,
        "tier": "red",
        "desc": "吸血 +5%，残血暴击 +20%",
        "stats": {"lifesteal": 0.05, "crit_chance": 0.20}
    })
    reactions.append({
        "id": "agility",
        "name": "身法凝形",
        "type": "tag_count",
        "tag": "agility",
        "min": 3,
        "tier": "green",
        "desc": "移速 +25%，闪避后残影",
        "stats": {"move_mul": 0.25}
    })
    reactions.append({
        "id": "expose",
        "name": "破绽尽显",
        "type": "tag_count",
        "tag": "expose",
        "min": 3,
        "tier": "gold",
        "desc": "暴击 +15%，暴伤 +40%",
        "stats": {"crit_chance": 0.15, "crit_damage": 0.40}
    })
    reactions.append({
        "id": "vitality",
        "name": "体魄护身",
        "type": "tag_count",
        "tag": "vitality",
        "min": 2,
        "tier": "green",
        "desc": "最大生命 +20%，减伤 8%",
        "stats": {"max_hp_pct": 0.20, "damage_reduce": 0.08}
    })
    reactions.append({
        "id": "formation",
        "name": "阵型玄机",
        "type": "tag_count",
        "tag": "formation",
        "min": 2,
        "tier": "gold",
        "desc": "召唤九宫护体阵，阵内击退",
        "stats": {}  # 行为层，Push 3.4
    })
    
    # === 五行相生（element_pair）===
    reactions.append({
        "id": "gold_wood",
        "name": "金木相生",
        "type": "element_pair",
        "elements": ["gold", "wood"],
        "tier": "green",
        "desc": "攻击 +12%，移速 +12%",
        "stats": {"damage_mul": 0.12, "move_mul": 0.12},
        "board_boosted": true  # 受邻接乘数加成
    })
    reactions.append({
        "id": "water_fire",
        "name": "水火相济",
        "type": "element_pair",
        "elements": ["water", "fire"],
        "tier": "green",
        "desc": "回血 +4/s，暴伤 +20%",
        "stats": {"hp_regen": 4.0, "crit_damage": 0.20},
        "board_boosted": true
    })
    
    # === 土定乾坤（earth_anchor）===
    reactions.append({
        "id": "earth_anchor",
        "name": "土定乾坤",
        "type": "earth_anchor",
        "tier": "green",
        "desc": "减伤 +15%，免击退",
        "stats": {"damage_reduce": 0.15},
        "board_boosted": true
    })
    
    # === 五行圆满（element_all）===
    reactions.append({
        "id": "wu_xing_full",
        "name": "五行圆满",
        "type": "element_all",
        "tier": "gold",
        "desc": "全属性 +15%，太极常驻护体",
        "stats": {
            "damage_mul": 0.15,
            "move_mul": 0.15,
            "crit_chance": 0.15,
            "crit_damage": 0.15,
            "damage_reduce": 0.15,
        },
        "board_boosted": true
    })
    
    # === 角色专属（tag_count）===
    reactions.append({
        "id": "role_yun",
        "name": "云清子·御剑千秋",
        "type": "tag_count",
        "tag": "yun_qingzi",
        "min": 3,
        "tier": "gold",
        "desc": "御剑常驻追击，攻击 +18%",
        "stats": {"damage_mul": 0.18}
    })
    reactions.append({
        "id": "role_mo",
        "name": "墨尘·笔走龙蛇",
        "type": "tag_count",
        "tag": "mo_chen",
        "min": 3,
        "tier": "gold",
        "desc": "笔画范围 +50%，处决阈值 25%",
        "stats": {}  # 行为层
    })
    reactions.append({
        "id": "role_yan",
        "name": "燕无归·残影追魂",
        "type": "tag_count",
        "tag": "yan_wugui",
        "min": 3,
        "tier": "gold",
        "desc": "闪避生成致命残影，暴击 +12%",
        "stats": {"crit_chance": 0.12}
    })
    reactions.append({
        "id": "role_mu",
        "name": "慕容·九宫太一",
        "type": "tag_count",
        "tag": "murong",
        "min": 3,
        "tier": "gold",
        "desc": "五行守护常驻，减伤 +12%",
        "stats": {"damage_reduce": 0.12}
    })

# ─── 核心：重新评估所有反应 ───
## equipped_relics: 当前装备的遗物 ID 数组
func evaluate(equipped_relics: Array) -> void:
    # 1. 统计 tag 数量
    var tag_counts: Dictionary = {}
    for rid in equipped_relics:
        var tags: Array = RelicDB.get_relic_tags(rid)
        for t in tags:
            if not tag_counts.has(t):
                tag_counts[t] = 0
            tag_counts[t] += 1
    
    # 2. 获取当前激活元素（来自五行盘）
    var active_elements: Array = WuxingBoard.get_active_elements()
    
    # 3. 遍历配方，判定激活
    var new_active: Array = []
    var old_active_ids: Array = []
    for r in active_reactions:
        old_active_ids.append(r.id)
    
    for recipe in reactions:
        var triggered: bool = false
        
        match recipe.type:
            "tag_count":
                var count: int = tag_counts.get(recipe.tag, 0)
                triggered = count >= recipe.min
            
            "element_pair":
                triggered = (recipe.elements[0] in active_elements) and \
                            (recipe.elements[1] in active_elements)
            
            "element_all":
                triggered = WuxingBoard.is_all_elements()
            
            "earth_anchor":
                triggered = WuxingBoard.has_earth_anchor()
        
        if triggered:
            # Path B 加成：元素反应受邻接乘数放大
            var final_stats: Dictionary = recipe.stats.duplicate()
            if recipe.get("board_boosted", false):
                var boost: float = _calc_board_boost(recipe)
                if boost != 1.0:
                    for key in final_stats:
                        if typeof(final_stats[key]) == TYPE_FLOAT:
                            final_stats[key] *= boost
            
            var activated: Dictionary = recipe.duplicate()
            activated.stats = final_stats
            new_active.append(activated)
    
    # 4. 对比差异，更新 GameState buff
    _apply_reaction_diff(old_active_ids, new_active)
    
    # 5. 更新缓存并发信号
    active_reactions = new_active
    reactions_changed.emit(active_reactions)

# ─── Path B：计算棋盘邻接对元素反应的加成 ───
## 取相关元素槽位的平均乘数
func _calc_board_boost(recipe: Dictionary) -> float:
    var boost: float = 1.0
    var count: int = 0
    
    match recipe.type:
        "element_pair":
            for elem in recipe.elements:
                var slot_mult: float = _get_element_avg_multiplier(elem)
                if slot_mult > 0:
                    boost *= slot_mult
                    count += 1
        
        "earth_anchor":
            var slot_mult: float = _get_element_avg_multiplier("earth")
            if slot_mult > 0:
                boost = slot_mult
        
        "element_all":
            # 五行圆满取所有槽位平均乘数
            var total: float = 0.0
            var filled: int = 0
            for i in range(5):
                if WuxingBoard.slot_elements[i] != "":
                    total += WuxingBoard.calc_slot_multiplier(i)
                    filled += 1
            if filled > 0:
                boost = total / filled
    
    return boost

## 获取某元素所在槽位的平均乘数（可能多个槽位放同元素）
func _get_element_avg_multiplier(element: String) -> float:
    var total: float = 0.0
    var count: int = 0
    for i in range(5):
        if WuxingBoard.slot_elements[i] == element:
            total += WuxingBoard.calc_slot_multiplier(i)
            count += 1
    if count == 0:
        return 0.0
    return total / count

# ─── 增量更新 buff ───
func _apply_reaction_diff(old_ids: Array, new_list: Array) -> void:
    var new_ids: Array = []
    var new_map: Dictionary = {}
    for r in new_list:
        new_ids.append(r.id)
        new_map[r.id] = r
    
    # 移除不再激活的
    for old_id in old_ids:
        if not old_id in new_ids:
            # 找旧配方的 stats 移除
            for old_r in reactions:
                if old_r.id == old_id:
                    GameState.remove_buff(old_r.stats)
                    break
    
    # 添加新激活的
    for new_id in new_ids:
        if not new_id in old_ids:
            GameState.apply_buff(new_map[new_id].stats)

# ─── 棋盘变化时重新评估 ───
func _on_board_changed() -> void:
    # 棋盘拓扑变化会影响 Path B 邻接乘数，需重算所有反应
    evaluate(equipped_relics)

# ─── 装备遗物变化时由遗物管理系统调用 ───
func set_equipped_relics(relics: Array) -> void:
    equipped_relics = relics.duplicate()
    evaluate(equipped_relics)

# ─── 查询接口 ───
func get_active_reactions() -> Array:
    return active_reactions

func is_reaction_active(reaction_id: String) -> bool:
    for r in active_reactions:
        if r.id == reaction_id:
            return true
    return false
