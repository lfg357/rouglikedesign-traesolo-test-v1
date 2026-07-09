extends Node
## 迷宫生成器 · LabyrinthGen
## 5×6 网格（GRID_W=5, GRID_H=6），每层最多 30 格
## 节点类型：MONSTER / ELITE / SHOP / EVENT / BOSS / START
## 生成有向无环图，保证从起点到 Boss 至少一条通路

class_name LabyrinthGen

const GRID_W: int = 5
const GRID_H: int = 6

enum NodeType { START, MONSTER, ELITE, SHOP, EVENT, BOSS }

# 生成结果：二维数组，每个格子存 {type, x, y, connections: []}
var grid: Array = []

# 每层房间配比（占总格数的比例）
var room_ratios: Dictionary = {
    "monster": 0.55,
    "elite": 0.12,
    "shop": 0.08,
    "event": 0.15,
}

func _ready() -> void:
    pass

## 生成一层迷宫
func generate_floor(floor_num: int) -> Array:
    grid = []
    for y in range(GRID_H):
        var row: Array = []
        for x in range(GRID_W):
            row.append(null)
        grid.append(row)
    
    # 1. 起点：左下角
    var start_x: int = 0
    var start_y: int = GRID_H - 1
    grid[start_y][start_x] = {
        "type": NodeType.START,
        "x": start_x,
        "y": start_y,
        "connections": []
    }
    
    # 2. Boss：右上角
    var boss_x: int = GRID_W - 1
    var boss_y: int = 0
    grid[boss_y][boss_x] = {
        "type": NodeType.BOSS,
        "x": boss_x,
        "y": boss_y,
        "connections": []
    }
    
    # 3. 填充中间格子
    var total_rooms: int = GRID_W * GRID_H
    var monster_count: int = int(total_rooms * room_ratios.monster)
    var elite_count: int = int(total_rooms * room_ratios.elite)
    var shop_count: int = max(1, int(total_rooms * room_ratios.shop))
    var event_count: int = int(total_rooms * room_ratios.event)
    
    var room_types: Array = []
    for i in range(monster_count):
        room_types.append(NodeType.MONSTER)
    for i in range(elite_count):
        room_types.append(NodeType.ELITE)
    for i in range(shop_count):
        room_types.append(NodeType.SHOP)
    for i in range(event_count):
        room_types.append(NodeType.EVENT)
    
    room_types.shuffle()
    
    # 4. 随机选择非起点非Boss的格子填充
    var empty_cells: Array = []
    for y in range(GRID_H):
        for x in range(GRID_W):
            if grid[y][x] == null:
                empty_cells.append(Vector2i(x, y))
    
    empty_cells.shuffle()
    
    # 只填充一部分，留空制造分支感
    var fill_count: int = min(room_types.size(), int(empty_cells.size() * 0.7))
    for i in range(fill_count):
        var pos: Vector2i = empty_cells[i]
        grid[pos.y][pos.x] = {
            "type": room_types[i],
            "x": pos.x,
            "y": pos.y,
            "connections": []
        }
    
    # 5. 建立连接（每个房间连向上/向右的邻居，如果存在）
    _build_connections()
    
    # 6. 确保从起点到 Boss 有通路（简单 BFS 验证）
    if not _has_path(start_x, start_y, boss_x, boss_y):
        # 强制打通一条路
        _carve_path(start_x, start_y, boss_x, boss_y)
        _build_connections()
    
    return grid

## 建立邻接连接
func _build_connections() -> void:
    for y in range(GRID_H):
        for x in range(GRID_W):
            if grid[y][x] == null:
                continue
            
            var connections: Array = []
            
            # 上
            if y > 0 and grid[y-1][x] != null:
                connections.append(Vector2i(x, y-1))
            # 下
            if y < GRID_H - 1 and grid[y+1][x] != null:
                connections.append(Vector2i(x, y+1))
            # 左
            if x > 0 and grid[y][x-1] != null:
                connections.append(Vector2i(x-1, y))
            # 右
            if x < GRID_W - 1 and grid[y][x+1] != null:
                connections.append(Vector2i(x+1, y))
            
            grid[y][x].connections = connections

## BFS 检查通路
func _has_path(sx: int, sy: int, ex: int, ey: int) -> bool:
    var visited: Array = []
    for y in range(GRID_H):
        visited.append([])
        for x in range(GRID_W):
            visited[y].append(false)
    
    var queue: Array = [Vector2i(sx, sy)]
    visited[sy][sx] = true
    
    while queue.size() > 0:
        var pos: Vector2i = queue.pop_front()
        if pos.x == ex and pos.y == ey:
            return true
        
        if grid[pos.y][pos.x] == null:
            continue
        
        for conn in grid[pos.y][pos.x].connections:
            if not visited[conn.y][conn.x]:
                visited[conn.y][conn.x] = true
                queue.append(conn)
    
    return false

## 强制打通一条路径（从起点到 Boss 走 L 形）
func _carve_path(sx: int, sy: int, ex: int, ey: int) -> void:
    var x: int = sx
    var y: int = sy
    
    # 先向右走到头
    while x < ex:
        if grid[y][x] == null:
            grid[y][x] = {
                "type": NodeType.MONSTER,
                "x": x, "y": y,
                "connections": []
            }
        x += 1
    
    # 再向上走到头
    while y > ey:
        if grid[y][x] == null:
            grid[y][x] = {
                "type": NodeType.MONSTER,
                "x": x, "y": y,
                "connections": []
            }
        y -= 1

## 获取节点类型中文名
func get_type_name(t: int) -> String:
    match t:
        NodeType.START: return "起点"
        NodeType.MONSTER: return "战斗"
        NodeType.ELITE: return "精英"
        NodeType.SHOP: return "商店"
        NodeType.EVENT: return "事件"
        NodeType.BOSS: return "Boss"
    return "未知"
