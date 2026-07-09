extends Node
## 五行盘 · 空间棋盘系统（Path B）
## 拓扑：外五边形（相生 ×1.5）+ 内五角星（相克 ×0.5）
## 每个元素顶点同时拥有 2 条生边 + 2 条克边
## 玩家将元素遗物放置到顶点，邻接关系决定乘数加成

# ─── 五行定义 ───
enum Element { GOLD, WATER, WOOD, FIRE, EARTH }

const ELEMENT_NAMES: Array = ["gold", "water", "wood", "fire", "earth"]
const ELEMENT_CN: Dictionary = {
    "gold": "金", "water": "水", "wood": "木", "fire": "火", "earth": "土"
}

# ─── 相生环（外五边形边）：金→水→木→火→土→金 ───
const SHENG_EDGES: Array = [
    ["gold", "water"],
    ["water", "wood"],
    ["wood", "fire"],
    ["fire", "earth"],
    ["earth", "gold"],
]

# ─── 相克边（内五角星边）：金克木、水克火、木克土、火克金、土克水 ───
const KE_EDGES: Array = [
    ["gold", "wood"],
    ["water", "fire"],
    ["wood", "earth"],
    ["fire", "gold"],
    ["earth", "water"],
]

const SHENG_MULTIPLIER: float = 1.5   # 相生加成
const KE_MULTIPLIER: float = 0.5      # 相克惩罚

# ─── 棋盘状态：5 个槽位，每个槽位存遗物 ID（空为 ""） ───
## 槽位索引 0-4 对应相生环顺序：金、水、木、火、土
## 玩家可以把任意元素遗物放到任意槽位（但最优解需要规划）
var slots: Array = ["", "", "", "", ""]  # 每个槽的遗物 ID
var slot_elements: Array = ["", "", "", "", ""]  # 每个槽的元素属性（缓存）

# 槽位索引 → 元素名的默认对应（用于 UI 渲染底图）
const SLOT_DEFAULT_ELEMENT: Array = ["gold", "water", "wood", "fire", "earth"]

signal board_changed()

# ─── 槽位操作 ───
## 放置遗物到指定槽位
func place_relic(slot_index: int, relic_id: String, element: String) -> void:
    if slot_index < 0 or slot_index >= 5:
        return
    slots[slot_index] = relic_id
    slot_elements[slot_index] = element
    board_changed.emit()

## 移除指定槽位遗物
func remove_relic(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= 5:
        return
    slots[slot_index] = ""
    slot_elements[slot_index] = ""
    board_changed.emit()

## 清空棋盘
func clear_board() -> void:
    slots = ["", "", "", "", ""]
    slot_elements = ["", "", "", "", ""]
    board_changed.emit()

# ─── 邻接查询 ───
## 获取某槽位的所有相邻槽位索引（4 个方向：2 生 + 2 克）
func get_adjacent_slots(slot_idx: int) -> Dictionary:
    var result: Dictionary = {"sheng": [], "ke": []}
    if slot_idx < 0 or slot_idx >= 5:
        return result
    
    var my_elem: String = SLOT_DEFAULT_ELEMENT[slot_idx]
    
    # 相生邻接（左右邻居）
    var sheng_left: int = (slot_idx - 1 + 5) % 5
    var sheng_right: int = (slot_idx + 1) % 5
    result.sheng.append(sheng_left)
    result.sheng.append(sheng_right)
    
    # 相克邻接（隔两个的对顶点）
    # 金(0)克木(2), 水(1)克火(3), 木(2)克土(4), 火(3)克金(0), 土(4)克水(1)
    for i in range(5):
        if i == slot_idx:
            continue
        if i in result.sheng:
            continue
        result.ke.append(i)
    
    return result

# ─── 乘数结算 ───
## 计算某个元素槽位的总邻接乘数（基于实际放置的元素）
## 注意：Path B 中玩家可自由摆放，邻接关系由"实际放置的两个元素"决定
## 即：如果两个相邻槽位的元素构成相生对 → ×1.5；构成相克对 → ×0.5
func calc_slot_multiplier(slot_idx: int) -> float:
    if slot_elements[slot_idx] == "":
        return 1.0
    
    var my_elem: String = slot_elements[slot_idx]
    var mult: float = 1.0
    var adj: Dictionary = get_adjacent_slots(slot_idx)
    
    # 检查所有 4 个邻接槽
    for adj_idx in adj.sheng + adj.ke:
        var adj_elem: String = slot_elements[adj_idx]
        if adj_elem == "":
            continue
        
        if _is_sheng_pair(my_elem, adj_elem):
            mult *= SHENG_MULTIPLIER
        elif _is_ke_pair(my_elem, adj_elem):
            mult *= KE_MULTIPLIER
    
    return mult

## 判断两个元素是否相生对
func _is_sheng_pair(a: String, b: String) -> bool:
    for edge in SHENG_EDGES:
        if (edge[0] == a and edge[1] == b) or (edge[0] == b and edge[1] == a):
            return true
    return false

## 判断两个元素是否相克对
func _is_ke_pair(a: String, b: String) -> bool:
    for edge in KE_EDGES:
        if (edge[0] == a and edge[1] == b) or (edge[0] == b and edge[1] == a):
            return true
    return false

# ─── 集合查询（兼容反应系统的 element_pair / element_all 判定） ───
## 获取当前装备的所有元素集合
func get_active_elements() -> Array:
    var result: Array = []
    for elem in slot_elements:
        if elem != "" and not elem in result:
            result.append(elem)
    return result

## 是否装备了某元素
func has_element(element: String) -> bool:
    return element in slot_elements

## 是否五行全齐
func is_all_elements() -> bool:
    var active: Array = get_active_elements()
    return active.size() == 5

## 土 + 其他元素 ≥ 2（土定乾坤判定）
func has_earth_anchor() -> bool:
    if not has_element("earth"):
        return false
    var others: int = 0
    for elem in slot_elements:
        if elem != "" and elem != "earth":
            others += 1
    return others >= 2

# ─── 棋盘总评（用于 UI 展示） ───
func get_board_summary() -> Dictionary:
    var sheng_count: int = 0
    var ke_count: int = 0
    var filled: int = 0
    
    for i in range(5):
        if slot_elements[i] != "":
            filled += 1
    
    # 统计所有有效邻接对（去重）
    var checked: Array = []
    for i in range(5):
        for j in range(i + 1, 5):
            if slot_elements[i] == "" or slot_elements[j] == "":
                continue
            var pair_key: String = str(i) + "-" + str(j)
            if pair_key in checked:
                continue
            checked.append(pair_key)
            
            if _is_sheng_pair(slot_elements[i], slot_elements[j]):
                # 还需要检查 i 和 j 是否真的几何相邻
                var adj_i: Dictionary = get_adjacent_slots(i)
                if j in adj_i.sheng or j in adj_i.ke:
                    sheng_count += 1
            elif _is_ke_pair(slot_elements[i], slot_elements[j]):
                var adj_i: Dictionary = get_adjacent_slots(i)
                if j in adj_i.sheng or j in adj_i.ke:
                    ke_count += 1
    
    return {
        "filled_slots": filled,
        "sheng_edges": sheng_count,
        "ke_edges": ke_count,
        "elements": get_active_elements(),
    }
