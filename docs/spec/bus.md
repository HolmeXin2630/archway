# BUS 组件设计规格

## 1. 解决的问题

之前最容易出问题的设计是把"当前访问主体"做成可变全局状态。这种方式在 fork / join、多个 sequence 并发执行时很危险，因为一个线程改了当前主体，另一个线程可能正好还在访问。

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

## 2. 公共类型

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

## 3. `BUS` Facade

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

## 4. `bus_master_handle`

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

## 5. `bus.slave` 预留定位

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

## 6. Burst 范围

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

## 7. 两个 core 的 BUS 示例

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
