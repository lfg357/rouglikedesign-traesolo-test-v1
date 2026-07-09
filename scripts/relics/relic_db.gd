extends Node
## 遗物数据库
## 所有遗物的元数据 + 协同标签 + 元素属性
## 遗物拾取后进入背包，玩家可放置到五行盘槽位

# ─── 稀有度 ───
enum Rarity { WHITE, BLUE, PURPLE, GOLD }

# ─── 遗物数据库 ───
## 每件遗物：
##   id: 唯一标识
##   name: 中文名
##   desc: 描述
##   element: 五行属（gold/water/wood/fire/earth/none）
##   synergy_tags: 协同标签数组
##   rarity: 稀有度
##   stats: 基础属性 buff
var relics: Dictionary = {}

func _ready() -> void:
    _init_relics()

# ─── 初始化遗物库 ───
func _init_relics() -> void:
    # === 金系 · 剑意 ===
    relics["qingping_sword"] = {
        "name": "青萍剑",
        "desc": "攻击 +15%，携带剑意标签",
        "element": "gold",
        "synergy_tags": ["sword_intent"],
        "rarity": Rarity.BLUE,
        "stats": {"damage_mul": 0.15}
    }
    relics["feijian_artifact"] = {
        "name": "飞剑符",
        "desc": "暴击 +8%，携带剑意标签",
        "element": "gold",
        "synergy_tags": ["sword_intent"],
        "rarity": Rarity.WHITE,
        "stats": {"crit_chance": 0.08}
    }
    relics["taixu_jianjue"] = {
        "name": "太虚剑诀",
        "desc": "暴伤 +30%，携带剑意标签",
        "element": "gold",
        "synergy_tags": ["sword_intent"],
        "rarity": Rarity.PURPLE,
        "stats": {"crit_damage": 0.30}
    }
    
    # === 水系 · 身法 ===
    relics["xueying_bu"] = {
        "name": "踏雪步",
        "desc": "移速 +15%，携带身法标签",
        "element": "water",
        "synergy_tags": ["agility"],
        "rarity": Rarity.BLUE,
        "stats": {"move_mul": 0.15}
    }
    relics["canxiang_fu"] = {
        "name": "残影符",
        "desc": "闪避后短暂隐身，携带身法标签",
        "element": "water",
        "synergy_tags": ["agility"],
        "rarity": Rarity.PURPLE,
        "stats": {"move_mul": 0.08}
    }
    relics["bingpo_zhu"] = {
        "name": "冰魄珠",
        "desc": "攻击附带迟滞，携带身法标签",
        "element": "water",
        "synergy_tags": ["agility"],
        "rarity": Rarity.WHITE,
        "stats": {}
    }
    
    # === 木系 · 体魄 ===
    relics["yijin_sutra"] = {
        "name": "易筋经残页",
        "desc": "最大生命 +15%，携带体魄标签",
        "element": "wood",
        "synergy_tags": ["vitality"],
        "rarity": Rarity.BLUE,
        "stats": {"max_hp_pct": 0.15}
    }
    relics["huishen_dan"] = {
        "name": "回神丹",
        "desc": "每秒回血 +2，携带体魄标签",
        "element": "wood",
        "synergy_tags": ["vitality"],
        "rarity": Rarity.WHITE,
        "stats": {"hp_regen": 2.0}
    }
    
    # === 火系 · 血怒 ===
    relics["xiehuo_xin"] = {
        "name": "邪火心",
        "desc": "残血时攻击 +25%，携带血怒标签",
        "element": "fire",
        "synergy_tags": ["blood_rage"],
        "rarity": Rarity.PURPLE,
        "stats": {"crit_chance": 0.05}
    }
    relics["lieyan_fu"] = {
        "name": "烈焰符",
        "desc": "攻击附带燃烧，携带血怒标签",
        "element": "fire",
        "synergy_tags": ["blood_rage"],
        "rarity": Rarity.BLUE,
        "stats": {"damage_mul": 0.08}
    }
    
    # === 土系 · 阵型/破绽 ===
    relics["kunlun_yin"] = {
        "name": "昆仑印",
        "desc": "减伤 +10%，携带破绽标签",
        "element": "earth",
        "synergy_tags": ["expose"],
        "rarity": Rarity.BLUE,
        "stats": {"damage_reduce": 0.10}
    }
    relics["pojia_zhen"] = {
        "name": "破甲阵图",
        "desc": "暴击伤害 +20%，携带破绽标签",
        "element": "earth",
        "synergy_tags": ["expose"],
        "rarity": Rarity.PURPLE,
        "stats": {"crit_damage": 0.20}
    }
    relics["bagua_zhen"] = {
        "name": "八卦阵盘",
        "desc": "领域范围扩大，携带阵型标签",
        "element": "earth",
        "synergy_tags": ["formation"],
        "rarity": Rarity.PURPLE,
        "stats": {"damage_reduce": 0.05}
    }
    
    # === 角色专属 ===
    relics["yan_whip"] = {
        "name": "燕无归·雪影鞭",
        "desc": "连击窗口延长，燕无归专属",
        "element": "water",
        "synergy_tags": ["yan_wugui", "agility"],
        "rarity": Rarity.GOLD,
        "stats": {"crit_chance": 0.05}
    }

# ─── 查询接口 ───
func get_relic(relic_id: String) -> Dictionary:
    if relics.has(relic_id):
        return relics[relic_id]
    return {}

func get_relic_element(relic_id: String) -> String:
    var r: Dictionary = get_relic(relic_id)
    return r.get("element", "none")

func get_relic_tags(relic_id: String) -> Array:
    var r: Dictionary = get_relic(relic_id)
    return r.get("synergy_tags", [])

func get_relic_stats(relic_id: String) -> Dictionary:
    var r: Dictionary = get_relic(relic_id)
    return r.get("stats", {})

## 按稀有度随机抽一件
func get_random_relic(min_rarity: int = Rarity.WHITE) -> String:
    var pool: Array = []
    for id in relics.keys():
        if relics[id].rarity >= min_rarity:
            pool.append(id)
    if pool.is_empty():
        return ""
    return pool[randi() % pool.size()]

## 三选一（遗物选择面板用）
func get_relic_choice(count: int = 3) -> Array:
    var all_ids: Array = relics.keys()
    all_ids.shuffle()
    return all_ids.slice(0, count)
