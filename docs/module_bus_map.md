# Archway 通用 SoC 验证框架 BUS / MAP 设计

## 1. 目标

构建一套可跨项目、跨层级复用的 SystemVerilog/UVM 通用验证基础框架。框架品牌名为 **Archway**。第一版先覆盖两个独立 package：

- `bus_pkg`：按最终地址进行统一访问，提供 `bus.master` 访问入口，并预留 `bus.slave` 挂载能力。
- `map_pkg`：按 view 查询 target 的 base / region，只负责 memory map。

目标是让不同项目、不同层级、不同 master 数量的 SoC 环境，都能使用尽量一致的调用方式。

### 1.1 设计意义

Archway 不是只为某一个项目写的一套工具，而是把 SoC 验证里反复出现、且每个项目都绕不开的共性需求抽象成稳定组件，让不同团队、不同项目都能基于同一套框架开发和阅读代码。

它带来的核心价值是：

- **统一风格**：相似问题用相似接口和组织方式，降低上手成本和阅读成本。
- **加快开发**：把 bus、map、config、装配等重复建设收敛成框架能力，让项目更快落地。
- **便于协作**：各组件按边界分工，其他人可以独立开发 bus / crg / iomux / power 等子组件。
- **便于扩展**：第一版先覆盖最小公共需求，后续可以在不推翻框架的前提下逐步加能力。
- **减少项目特例污染**：把项目差异留在项目层，把通用能力沉淀到 common framework。

### 1.2 基本框架思路

Archway 的基本思路是：先抽象出 SoC 验证中必然存在的共性资源和共性流程，再把这些能力拆成可插拔 package，通过统一的 facade、config 和 env 装配成项目可用的运行时框架。

它也适合多人协作开发：bus、map、crg、iomux、power 等能力可以由不同成员并行实现，只要遵守统一的命名、配置和装配约定，最后就能汇入同一个 Archway 运行时环境。

更具体地说：

1. **资源层**：`BUS`、`MAP` 等 Facade 提供统一资源入口。
2. **配置层**：各组件 YAML 生成各自的 config 对象，并在 `build_phase` 前完成校验与冻结。
3. **装配层**：`archway_env` 负责显式依赖、拓扑排序和组件 env 装配。
4. **实现层**：项目组件 env 负责创建具体 UVM agent / adapter / checker，并注册到框架中。
5. **使用层**：测试和 sequence 只面对稳定 API，不关心底层项目实现细节。

这个分层的目标不是做一个“大而全”的统一模型，而是让框架保持轻、稳、可组合，随着项目数量增加而持续受益。

示例使用方式：

```systemverilog
map_region region;
bus_master_handle m;

void'(MAP::view("core0").get_region("uart0", region));

m = BUS::master("core0");
m.write(region.base + 'h10, data, 4);
m.burst_write(region.base + 'h100, data_arr, 4, BUS_BURST_INCR);
```

---

## 2. 设计原则

1. 常用访问路径要简单。
2. 不要使用可变的全局当前 master，例如 `set_master()`。
3. `bus_pkg` 和 `map_pkg` 必须彼此独立。
4. `map_pkg` 只负责查询 base / region；最终地址组合由用户、RAL 或项目层代码按需完成，第一版不提供强制的 `ARCHWAY::master(...).write(target, offset, ...)` 组合访问入口。
5. 常规 burst 访问不要强制用户先构造 request object。
6. 第一版不要把 AXI/AHB 的所有协议细节都塞进主接口。
7. 项目差异通过初始化阶段注册进去，而不是写死在 common package 里。
8. Facade 只保存资源索引，不保存当前选择状态。
9. 多 `archway_env` 并存时，注册名必须带作用域前缀或显式命名空间，避免资源名冲突。
10. `build_phase` 开始后，组件 config 冻结不可改。
11. 进入 `build_phase` 之前，可以由项目代码或 `archway_env` 内部先做前置校验，但不自造新的 UVM phase。
12. 前置校验由 `archway_env` 统一编排，各组件自行校验自己的 config，env 再做跨组件依赖和冲突检查。
13. 装配顺序按显式依赖关系做拓扑排序，而不是写死固定顺序。
14. 组件依赖优先写在 config 里，由 `archway_env` 读取后统一排序和装配。
15. 资源 API 使用类型明确命名：`has_<resource>()` 用于探测，`<resource>()` 用于获取且找不到时 fatal，`get_<resource>_names()` 用于枚举。
16. 底层组件设计尽量遵循 SOLID 原则，并具体化为以下框架规则：
    - 一个 package 只负责一种能力，不跨包做组合逻辑。
    - Facade 只做资源索引，不承载具体后端实现。
    - handle 基类只定义最小稳定接口，项目能力通过派生类或扩展接口增加。
    - YAML parser 输出 config 对象，不直接创建 UVM agent。
    - config 对象以纯数据为主，可以带少量自校验方法，但不能创建 agent、注册 Facade、启动 sequence 或访问 DUT。
    - 提供很薄的 `archway_config_base`，统一 config 的 validate/freeze 语义。
    - config 校验接口使用 pure virtual `function void validate(ref string errors[$])` 形式，要求子类必须实现；组件追加错误信息，`archway_env` 根据 `errors.size()` 汇总后统一 fatal。
    - `freeze()` 不做 pure virtual，由基类提供默认实现设置 `frozen = 1`；子类如需扩展可 override，但必须调用 `super.freeze()`。
    - v1 不强制字段级 freeze 检测；基类可提供 `check_not_frozen(field_name)` helper，供子类 setter 按需使用。
    - 避免把项目特例写进 common package。
    - 组件间连接关系第一版完全显式依赖驱动，不预设固定约定依赖；`archway_env` 只负责拓扑排序和装配，不硬编码组件顺序。
    - 框架内部成员变量使用 `m_` 前缀，局部临时变量保持普通命名，不额外引入 `local_` 前缀。

---

## 3. Package 边界

### 3.1 `bus_pkg`

`bus_pkg` 负责按 endpoint-view address 进行访问。

它提供：

- `BUS`
- `bus_master_handle`
- endpoint 注册
- 单次 read/write API
- burst read/write API
- 公共 bus 类型和 status 枚举

它不提供：

- memory map 查询
- target 名称解析
- YAML / IP-XACT 解析
- RAL 建模
- 主接口里直接暴露 AXI / AHB / APB 的协议字段

`bus_pkg` 不能依赖 `map_pkg`。

### 3.2 `map_pkg`

`map_pkg` 负责按 view 查询 target 的 base / region。

它提供：

- `MAP`
- `map_view`
- `map_region`
- 可选的 `map_fragment`，用于大 SoC 的分片组合
- view 注册
- target 到 region 的查询

它不提供：

- bus 访问执行
- 最终地址访问
- 协议转换
- burst 行为

`map_pkg` 不能依赖 `bus_pkg`。

### 3.3 `archway_pkg`

`archway_pkg` 是 Archway 的框架顶层组装 package，包含：
- `archway_env`：统一装配容器，不是 `BUS + MAP` 的强制组合访问层
- `ARCHWAY` Facade：框架级资源入口

v1 采用“每个能力一个组件 env”的结构。项目 env 显式创建并注册项目组件 env，不依赖 factory override 隐式替换组件 env 类型。

```text
tb_top
  ↓ interface 实例化和 vif 挂载
uvm_test
  ↓ 例化项目 env
act_env extends archway_env
  ↓ enable_bus / enable_map / enable_crg
  ↓ 显式创建 act_archway_bus_env / act_archway_map_env
  ↓ 通过 register_bus_env / register_map_env 注册组件 env
act_archway_bus_env extends archway_bus_env
  ↓ 创建项目实际 bus agent / adapter / handle，并注册到 BUS Facade
真实 bus agent / sequencer / monitor / checker
```

它负责：

- 收集各组件独立产生的 config 对象。
- 基类 `build_phase` 采用 template method：先调用 `super.build_phase(phase)`，再调用项目可重载的配置 hook，随后统一加载各组件 YAML、生成 config、校验、freeze、检查 enable/register 是否匹配，并完成基础装配。
- 项目 env 默认不重载 `build_phase`，只重载必要的 Archway 配置 hook。
- 基类 `build_phase` 设置内部状态 flag；如果用户重载 `build_phase` 导致基类流程未执行，则在 `connect_phase` 一开始 `uvm_fatal`。
- 在 `connect_phase` 绑定组件间显式依赖。
- 在 `run_phase` 保持被动，不主动发起验证行为。

它可以配合一个轻量 `ARCHWAY` Facade，作为框架级资源入口，例如：

```systemverilog
archway_env env;

ARCHWAY::register_env("default", this);
env = ARCHWAY::get_env("default");
if (ARCHWAY::has("bus")) begin
  // component exists
end
```

默认命名固定为 `default`；多 env 场景使用显式名称，例如 `chip0`、`chip1`。

`remove_env` 仅表示注销注册关系，不强调销毁对象本身；普通芯片验证仿真通常不依赖显式销毁对象来获得性能收益。

轻量 `ARCHWAY` Facade 只用于注册、查询和获取框架级资源，不参与具体访问。

它不提供：

- `ARCHWAY::master(...).write(target, offset, ...)` 这类默认绑定 `MAP view` 和 `BUS master` 的组合访问入口。
- memory map 查询逻辑。
- bus 访问执行逻辑。
- 项目专有验证流程。

常规访问由用户或项目层代码自行组合：

```systemverilog
map_region region;
bus_master_handle m;

void'(MAP::view("core0").get_region("uart0", region));
m = BUS::master("core0");
m.write(region.base + offset, data, 4);
```

---

## 4. BUS 设计

### 4.1 解决的问题

之前最容易出问题的设计是把“当前访问主体”做成可变全局状态。这种方式在 fork / join、多个 sequence 并发执行时很危险，因为一个线程改了当前主体，另一个线程可能正好还在访问。

现在改成不可变 handle：

```systemverilog
bus_master_handle h0 = BUS::master("core0");
bus_master_handle h1 = BUS::master("core1");
```

每个 handle 只指向一个注册好的 endpoint，不会修改全局当前状态。

master 名称支持作用域写法，用于多 env / 多 chip 联仿场景；单 env 场景不强制使用作用域。作用域分隔符固定为 `.`。第一版不解析作用域层级，不自动加前缀，不维护 scope tree；registry 只把完整名称当作普通 string key。例如：

```systemverilog
BUS::master("core0");
BUS::master("chip0.core0");
BUS::master("chip1.core0");
```

### 4.2 公共类型

第一版公共类型如下：

```systemverilog
typedef bit [63:0]   bus_addr_t;
typedef bit [1023:0] bus_data_t;

typedef enum {
  BUS_OK,
  BUS_ERROR,
  BUS_UNSUPPORTED,
  BUS_TIMEOUT,
  BUS_DECODE_ERROR,
  BUS_ALIGN_ERROR
} bus_status_e;

typedef enum {
  BUS_BURST_SINGLE,
  BUS_BURST_INCR,
  BUS_BURST_WRAP,
  BUS_BURST_FIXED
} bus_burst_kind_e;
```

`bus_data_t` 故意设计得比常见 bus width 更宽。实际有效字节数由 `n_bytes` 或 `beat_bytes` 指定。

### 4.3 `BUS` Facade

最小 API：

```systemverilog
class BUS;
  static function void register(string name, bus_master_handle h);
  static function bit has_master(string name);
  static function bus_master_handle master(string name = "default");
endclass
```

`BUS::has_master(name)` 只检查资源是否存在，不报错；`BUS::master(name)` 找不到资源时直接 `uvm_fatal`。重复注册同名 master 时记录 `uvm_error` 并拒绝覆盖。

如果后续需要，也可以补充默认 wrapper，例如 `BUS::write(...)`，其本质就是调用 `BUS::master("default")`。

### 4.4 `bus_master_handle`

`bus_master_handle` 是用户真正拿来用的代理句柄。

第一版把接口分成两层：

1. **主接口**：不带 `status`，适合大多数正向测试。主接口失败时只记录 `uvm_error` 和错误类型，不 `uvm_fatal`。
2. **检查接口**：带 `status`，适合 negative test、边界检查和显式结果判断。

最小 API：

```systemverilog
class bus_master_handle extends uvm_object;
  virtual task write(
    input  bus_addr_t addr,
    input  bus_data_t data,
    input  int unsigned n_bytes = 0
  );

  virtual task read(
    input  bus_addr_t addr,
    output bus_data_t data,
    input  int unsigned n_bytes = 0
  );

  virtual task burst_write(
    input  bus_addr_t addr,
    input  bus_data_t data[],
    input  int unsigned beat_bytes = 0,
    input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
  );

  virtual task burst_read(
    input  bus_addr_t addr,
    output bus_data_t data[],
    input  int unsigned num_beats,
    input  int unsigned beat_bytes = 0,
    input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
  );

  virtual task try_write(
    output bus_status_e status,
    input  bus_addr_t addr,
    input  bus_data_t data,
    input  int unsigned n_bytes = 0
  );

  virtual task try_read(
    output bus_status_e status,
    input  bus_addr_t addr,
    output bus_data_t data,
    input  int unsigned n_bytes = 0
  );

  virtual task try_burst_write(
    output bus_status_e status,
    input  bus_addr_t addr,
    input  bus_data_t data[],
    input  int unsigned beat_bytes = 0,
    input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
  );

  virtual task try_burst_read(
    output bus_status_e status,
    input  bus_addr_t addr,
    output bus_data_t data[],
    input  int unsigned num_beats,
    input  int unsigned beat_bytes = 0,
    input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
  );
endclass
```

语义约定：

- `n_bytes = 0` 表示使用 endpoint 默认单次访问宽度。
- `beat_bytes = 0` 表示使用 endpoint 默认 burst beat 宽度。
- write burst 的 `num_beats = data.size()`。
- read burst 的 `num_beats` 需要显式传入。
- `BUS_BURST_INCR` 是默认 burst 模式。
- 主接口只记录 `uvm_error` 和错误类型；需要显式检查返回结果时，使用 `try_*` 接口。

### 4.5 `bus.slave` 预留定位

`bus.slave` 第一版只预留注册、获取、枚举能力，用于让 bus verification sequence 发现当前环境中有哪些 slave 资源。

最小 API：

```systemverilog
class BUS;
  static function void register_slave(string name, bus_slave_handle h);
  static function bit has_slave(string name);
  static function bus_slave_handle slave(string name);
  static function void get_master_names(ref string names[$]);
  static function void get_slave_names(ref string names[$]);
endclass
```

`BUS::has_slave(name)` 只检查资源是否存在，不报错；`BUS::slave(name)` 找不到资源时直接 `uvm_fatal`。重复注册同名 slave 时记录 `uvm_error` 并拒绝覆盖。

`BUS` Facade 可以提供 master/slave 资源迭代能力，方便 bus verification sequence 自行组合随机访问场景；但 `BUS` 不内置随机验证算法。第一版枚举接口不提供 scope/filter，统一返回全部注册名称；如果需要过滤，由上层按 string 自行处理，后续版本再考虑内建过滤能力。

示例：

```systemverilog
string masters[$];
string slaves[$];

BUS::get_master_names(masters);
BUS::get_slave_names(slaves);

foreach (masters[i]) begin
  foreach (slaves[j]) begin
    // sequence 自行结合 MAP 或项目配置生成访问
  end
end
```

slave 的 region 信息优先复用 `map_pkg` 中的 `map_region` / `map_view`。`bus_pkg` 不依赖 `map_pkg`，因此第一版不在 `bus_slave_handle` 基类中定义 `get_region()`。

`BUS::get_slave_names()` 返回 plain string name；如果需要 region，由上层 test / sequence / project layer 同时使用 `MAP::view(...).get_region(name, region)` 查询，不形成 `bus_pkg` 与 `map_pkg` 之间的 package 依赖。

响应控制、error injection、wait/stall、capability 描述、memory load/peek 等能力记录为 v2 待扩展项，不进入 v1 最小公共接口。

### 4.6 Burst 范围

第一版只覆盖 AHB / AXI 常见 burst 语义：

- 起始地址
- beat size
- beat 数量
- burst 类型：`SINGLE` / `INCR` / `WRAP` / `FIXED`
- 读写数据
- response status

先不把这些协议细节放进主接口：

- AXI ID
- AXI CACHE / PROT / QOS / LOCK / REGION
- AXI 每 beat 的 WSTRB
- AHB HPROT / HMASTER
- 负向测试的预期响应
- 自定义 split policy 覆盖

这些后面可以加扩展路径，但第一版主接口必须保持简单。

### 4.6 两个 core 的 BUS 示例

```systemverilog
bus_data_t   data;
bus_data_t   burst_data[];

BUS::master("core0").write('h8000_0010, data, 4);
BUS::master("core1").write('h4000_0010, data, 4);

fork
  BUS::master("core0").burst_write('h9000_0000, burst_data, 4, BUS_BURST_INCR);
  BUS::master("core1").burst_write('hA000_0000, burst_data, 8, BUS_BURST_INCR);
join
```

这里没有任何全局 current core 被修改。

---

## 5. MAP 设计

### 5.1 解决的问题

大 SoC 的 memory map 往往非常大，不适合塞成一个巨大的全局表，也不适合放到 BUS 里。

MAP 只回答一件事：

```text
在某个 view 下，某个 target 的 base / region 是什么？
```

MAP 不执行访问，也不返回 final address。它只维护 target / base / size 的描述。

### 5.2 公共类型

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

### 5.3 `map_region`

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

### 5.4 `map_view`

`map_view` 表示某个视角，例如：

- `core0`
- `core1`
- `sys`
- `debug`

view 名称支持与 `BUS::master(...)` 一致的作用域写法，用于多 env / 多 chip 联仿场景；单 env 场景不强制使用作用域。作用域分隔符固定为 `.`。第一版不解析作用域层级，不自动加前缀，不维护 scope tree；registry 只把完整名称当作普通 string key。例如：

```systemverilog
MAP::view("core0");
MAP::view("chip0.core0");
MAP::view("chip1.core0");
```

最小 API：

```systemverilog
class map_view extends uvm_object;
  function void add_region(
    input string target,
    input map_addr_t base,
    input map_addr_t size
  );

  function void get_region(
    input  string target,
    output map_region region
  );

  function bit has_region(
    input string target
  );

  function bit get_base(
    input  string target,
    output map_addr_t base
  );
endclass
```

建议优先使用 `get_region()`，因为它同时返回 base 和 size。`has_region()` 只检查 target 是否存在，不报错；`get_region()` 找不到 target 时直接 `uvm_fatal`。`get_base()` 只是方便接口。

### 5.5 `MAP` Facade

最小 API：

```systemverilog
class MAP;
  static function void register_view(string name, map_view v);
  static function bit has_view(string name);
  static function map_view view(string name);
  static function void get_view_names(ref string names[$]);
endclass
```

`MAP::has_view(name)` 只检查资源是否存在，不报错；`MAP::view(name)` 找不到资源时直接 `uvm_fatal`。重复注册同名 view 时记录 `uvm_error` 并拒绝覆盖。

### 5.6 第一版 MAP 能力边界

第一版支持：

- 命名 view
- 命名 target
- 每个 target 的 base 和 size
- 直接注册 region
- 通过 view 查 target

第一版暂不支持：

- 按 offset 计算 final address
- bus 访问执行
- 动态 remap
- 完整权限矩阵
- 复杂地址转换函数
- 强制 IP-XACT 支持

### 5.7 两个 core 的 MAP 示例

```systemverilog
map_view core0_map;
map_view core1_map;
map_region r0;
map_region r1;

core0_map = map_view::type_id::create("core0_map");
core1_map = map_view::type_id::create("core1_map");

core0_map.add_region("uart0", 'h8000_0000, 'h1000);
core1_map.add_region("uart0", 'h4000_0000, 'h1000);

MAP::register_view("core0", core0_map);
MAP::register_view("core1", core1_map);

void'(MAP::view("core0").get_region("uart0", r0));
void'(MAP::view("core1").get_region("uart0", r1));
```

---

## 6. 组合方式

第一版不引入额外的 `SOC` 组合 Facade。`BUS` 和 `MAP` 保持独立，组合逻辑由项目层或测试层自己完成，避免框架在第一版就多出一层薄封装和重复语义。

典型写法是：

```systemverilog
map_region region;
bus_master_handle m;

void'(MAP::view("core0").get_region("uart0", region));
m = BUS::master("core0");
m.write(region.base + 'h10, data, 4);
```

如果后续项目强烈需要 target-relative 便捷层，可以在各项目自己的接入层里再封装，不作为 Archway v1 的公共核心能力。

---

## 7. 项目初始化示例

项目环境负责注册自己的 BUS handles 和 MAP views。

```systemverilog
class my_env extends uvm_env;
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // BUS 注册
    BUS::register("core0", core0_bus_master_handle);
    BUS::register("core1", core1_bus_master_handle);

    // MAP 注册
    core0_map.add_region("uart0", 'h8000_0000, 'h1000);
    core1_map.add_region("uart0", 'h4000_0000, 'h1000);

    MAP::register_view("core0", core0_map);
    MAP::register_view("core1", core1_map);
  endfunction
endclass
```

对于更大的项目，可以从 YAML 或 IP-XACT 导入这些注册信息。导入器不应该放在 `bus_pkg` 或 `map_pkg` 里，而应作为独立的项目接入逻辑。

---

## 8. 外部描述文件

第一版只支持 YAML 作为配置输入源，但不是一份全局大 YAML。各子组件自行定义自己的 YAML 文件和格式，例如 bus YAML、map YAML、crg YAML。后续如果需要 IP-XACT，可以先在框架外转换成对应组件的 YAML，再交给该组件处理。

`archway_config_base` 放在独立的 `archway_core_pkg` 中，供 `bus_pkg`、`map_pkg`、`crg_pkg` 等组件包复用，避免基础类型依赖落到某个具体组件包里。v1 的 `archway_core_pkg` 只放 `archway_config_base`，避免 core package 变成杂项集合。`bus_config`、`map_config` 等组件 config 均继承 `archway_config_base`，便于 `archway_env` 统一收集和校验。

`archway_env` 不自动扫描目录；项目 env 显式指定启用哪些组件以及对应 YAML 路径。用户侧使用类型化 helper，例如 `enable_map`、`enable_bus`、`enable_crg`，避免同时填写 instance name 和 type name。v1 采用 template method 模式：项目 env 默认不重载 `build_phase`，只重载必要的 Archway 配置 hook；该 hook 可以完成 enable/register 以及项目组件 env 的创建。基类 `build_phase` 统一完成配置加载、校验、freeze 和组件装配。

```systemverilog
class act_env extends archway_env;
  act_archway_bus_env bus_env;
  act_archway_map_env map_env;

  virtual function void configure_archway();
    // 单实例：省略 instance name，默认实例名使用 archway 前缀，便于 UVM log 中区分来源
    // enable_map 默认 instance name = "archway_map"
    // enable_bus 默认 instance name = "archway_bus"
    enable_map("cfg/map.yaml");
    enable_bus("cfg/bus.yaml");

    bus_env = act_archway_bus_env::type_id::create("archway_bus", this);
    map_env = act_archway_map_env::type_id::create("archway_map", this);

    register_bus_env(bus_env);
    register_map_env(map_env);
  endfunction
endclass
```

多实例时显式指定 instance name。文档建议带项目/芯片前缀和 archway 标识，便于 UVM log 定位，但框架不强制校验命名格式：

```systemverilog
enable_map("chip0_archway_map", "cfg/chip0/map.yaml");
enable_bus("chip0_archway_bus", "cfg/chip0/bus.yaml");
enable_map("chip1_archway_map", "cfg/chip1/map.yaml");
enable_bus("chip1_archway_bus", "cfg/chip1/bus.yaml");
```

底层如需统一实现，可以内部转成 `enable_component(instance_name, type_name, yaml_path)`，但三参数形式不作为 v1 常用用户 API。基类 `build_phase` 会设置内部状态 flag；如果项目重载 `build_phase` 且未调用基类流程，`connect_phase` 一开始必须 `uvm_fatal`。

下面是 map 组件的 YAML 示例：

```yaml
views:
  core0:
    regions:
      uart0:
        base: 0x80000000
        size: 0x1000
  core1:
    regions:
      uart0:
        base: 0x40000000
        size: 0x1000
```

YAML 导入器最终应生成等价调用：

```systemverilog
core0_map.add_region("uart0", 'h8000_0000, 'h1000);
core1_map.add_region("uart0", 'h4000_0000, 'h1000);
```

IP-XACT 可以在后续加入，但最终也应该转换成同样简单的 `map_view / map_region` 内部模型。

---

## 9. 这套设计相比前面方案的改进

1. **并发更安全**：不再依赖全局可变 current master。
2. **使用更简单**：常规 read/write/burst 保持直接调用。
3. **包边界更清楚**：BUS 和 MAP 完全独立。
4. **耦合更低**：第一版不引入 target-relative 组合 Facade，不把 MAP 逻辑塞进 BUS。
5. **扩展更稳**：高级协议信息以后可以再扩，不影响第一版 API。
6. **多 master 更清晰**：`BUS::master("core0")` 和 `BUS::master("dma0")` 语义直接明了。

---

## 10. 第一版非目标

第一版不做：

- builder-style 链式 API
- 常规 burst 强制 request object
- 在主接口里完整建模 AXI 全部属性
- BUS 和 MAP 的直接依赖
- 动态 remap
- 安全 / firewall / power / clock 联动
- 完整 IP-XACT 语义导入
- 非 YAML 的直接配置输入
- RAL frontdoor 集成

这些都可以后续逐步加，不应阻塞第一版落地。

---

## 11. 第一版实现决定

第一版明确采用以下决定：

1. facade 类名使用大写：`BUS`、`MAP`。
2. 第一版不引入额外的 `SOC` 组合 Facade，也不提供 `ARCHWAY::master(...)` 这类 target-relative 便捷层；组合逻辑由项目层或测试层自行完成。
3. 找不到 endpoint / view / target 时，第一版直接 `uvm_fatal`，避免静默失败。
4. `bus_master_handle` 先作为公共基类使用；如果后续多个 endpoint 出现重复转发逻辑，再考虑拆成 endpoint/backend 两层。
5. `archway_env` 的标准入口是显式 `configure_archway()`，而不是要求用户在 `build_phase` 里把 `super` 放在末尾。

这些决定都以“第一版尽量小、尽量简单”为原则。

