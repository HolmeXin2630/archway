# MAP 组件设计规格

## 1. 解决的问题

大 SoC 的 memory map 往往非常大，不适合塞成一个巨大的全局表，也不适合放到 BUS 里。

MAP 只回答一件事：

```text
在某个 view 下，某个 target 的 base / region 是什么？
```

MAP 不执行访问，也不返回 final address。它只维护 target / base / size 的描述。

## 2. 公共类型

```systemverilog
typedef bit [63:0] map_addr_t;

typedef enum {
  MAP_OK,
  MAP_NO_VIEW,
  MAP_NO_TARGET,
  MAP_OVERLAP,
  MAP_ERROR
} map_status_e;
```

## 3. `map_region`

第一版 region 只保留最小字段：

```systemverilog
class map_region extends uvm_object;
  string     target;
  map_addr_t base;
  map_addr_t size;
endclass
```

后续版本可以再加属性，例如：

- cacheability
- security 属性
- device / memory 类型
- 访问权限
- 所属 subsystem

## 4. `map_view`

`map_view` 表示一个视角，例如 `core0`、`core1` 或 `debug`。同一个 target 在不同 view 下可以有不同的 base。

它提供：

- `add_region(target, base, size)`
- `has_region(target)`
- `get_region(target, region)`
- `get_base(target, base)`
- `get_target_names()`

## 5. `MAP` Facade

`MAP` 负责 view 注册、获取和枚举：

- `register_view(name, view)`
- `has_view(name)`
- `view(name)`
- `get_view_names()`

重复注册同名 view 应记录 `uvm_error` 并拒绝覆盖。

## 6. 使用方式

```systemverilog
map_region region;

void'(MAP::view("core0").get_region("uart0", region));
BUS::master("core0").write(region.base + 'h10, data, 4);
```

## 7. 设计边界

`map_pkg` 不负责：

- bus 执行
- 协议转换
- burst 行为
- 最终地址访问语义

`map_pkg` 和 `bus_pkg` 必须保持 package 独立。
