extends Node
## 商店系统 · 经济支出
## 三层货币 sink：灵气 / 灵石 / 业力
## 层内商店（卦摊）消费灵气 + 灵石
## 层间结算屏消费灵石
## 局外业力商店

class_name ShopSystem

# ─── 灵气商品（层内，花或丢） ───
var qi_items: Array = [
    {"id": "heal_pill", "name": "回血丹", "desc": "恢复 30% 最大生命", "price": 15, "currency": "qi"},
    {"id": "mp_pill", "name": "回灵丹", "desc": "回满灵力", "price": 15, "currency": "qi"},
    {"id": "white_relic", "name": "白色遗物（随机）", "desc": "赌狗快乐，低稀有度", "price": 25, "currency": "qi"},
    {"id": "blue_relic", "name": "蓝色遗物（概率）", "desc": "中层赌注", "price": 60, "currency": "qi"},
    {"id": "altar_attack", "name": "攻击祭坛·本层", "desc": "本层攻击 +5%", "price": 40, "currency": "qi"},
    {"id": "altar_hp", "name": "生命祭坛·本层", "desc": "本层最大生命 +10%", "price": 40, "currency": "qi"},
    {"id": "reroll", "name": "重铸", "desc": "重随一件遗物次级词条", "price": 30, "currency": "qi"},
]

# ─── 灵石商品（层间 / 层内商店） ───
var stone_items: Array = [
    {"id": "relic_blue", "name": "青蓝遗物", "desc": "蓝色品质遗物", "price": 40, "currency": "stone"},
    {"id": "relic_purple", "name": "绛紫遗物", "desc": "紫色品质遗物", "price": 90, "currency": "stone"},
    {"id": "relic_gold", "name": "鎏金遗物", "desc": "金色品质遗物", "price": 160, "currency": "stone"},
    {"id": "skill_reroll", "name": "技能重铸", "desc": "调整技能组", "price": 50, "currency": "stone"},
    {"id": "slot_expand", "name": "槽位扩展", "desc": "遗物槽位 +1（递增定价）", "price": 30, "currency": "stone", "price_scale": 1.5},
]

# ─── 业力商品（meta，永久） ───
var karma_items: Array = [
    {"id": "unlock_char", "name": "解锁新角色", "desc": "解锁一位可玩角色", "price": 500, "currency": "karma"},
    {"id": "unlock_relic", "name": "新遗物进池", "desc": "扩充遗物池", "price": 300, "currency": "karma"},
    {"id": "unlock_skill", "name": "新技能进池", "desc": "扩充技能池", "price": 300, "currency": "karma"},
    {"id": "talent_slot", "name": "天赋槽 +1", "desc": "增加起始天赋槽位", "price": 200, "currency": "karma"},
    {"id": "start_relic", "name": "起始遗物预设", "desc": "开局携带指定遗物", "price": 150, "currency": "karma"},
]

# 槽位扩展当前等级
var slot_expand_level: int = 0
const MAX_SLOTS: int = 8
const BASE_SLOTS: int = 3

signal purchase_successful(item_id: String)
signal purchase_failed(reason: String)

# ─── 购买接口 ───
func buy_item(item_id: String) -> bool:
    var item: Dictionary = _find_item(item_id)
    if item.is_empty():
        purchase_failed.emit("商品不存在")
        return false
    
    var price: int = _get_current_price(item)
    
    match item.currency:
        "qi":
            if not GameState.spend_qi(price):
                purchase_failed.emit("灵气不足")
                return false
        "stone":
            if not GameState.spend_spirit_stone(price):
                purchase_failed.emit("灵石不足")
                return false
        "karma":
            if GameState.player_karma < price:
                purchase_failed.emit("业力不足")
                return false
            GameState.player_karma -= price
            GameState.currency_changed.emit()
    
    # 执行效果
    _apply_item_effect(item)
    
    # 槽位扩展涨价
    if item_id == "slot_expand":
        slot_expand_level += 1
    
    purchase_successful.emit(item_id)
    return true

# ─── 查询价格 ───
func get_price(item_id: String) -> int:
    var item: Dictionary = _find_item(item_id)
    if item.is_empty():
        return -1
    return _get_current_price(item)

func _get_current_price(item: Dictionary) -> int:
    var base: int = item.price
    if item.has("price_scale") and item.id == "slot_expand":
        # 递增定价：30→50→80→120→180
        var prices: Array = [30, 50, 80, 120, 180]
        if slot_expand_level < prices.size():
            return prices[slot_expand_level]
        return prices[prices.size() - 1]
    return base

# ─── 商品查找 ───
func _find_item(item_id: String) -> Dictionary:
    for item in qi_items + stone_items + karma_items:
        if item.id == item_id:
            return item
    return {}

# ─── 商品效果 ───
func _apply_item_effect(item: Dictionary) -> void:
    match item.id:
        "heal_pill":
            # 回 30% 血
            var player: Node = get_tree().get_first_node_in_group("player")
            if player and player.has_method("heal"):
                var heal_amount: int = int(GameState.get_player_max_hp() * 0.3)
                player.heal(heal_amount)
        
        "white_relic", "blue_relic", "relic_blue", "relic_purple", "relic_gold":
            # 获得随机遗物（由遗物管理系统处理）
            pass
        
        "altar_attack":
            GameState.apply_buff({"damage_mul": 0.05})
        
        "altar_hp":
            GameState.apply_buff({"max_hp_pct": 0.10})
        
        "slot_expand":
            # 槽位扩展（遗物系统处理）
            pass

## 获取当前最大槽位数
func get_max_slots() -> int:
    return min(BASE_SLOTS + slot_expand_level, MAX_SLOTS)
