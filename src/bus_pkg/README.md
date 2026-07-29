# bus_pkg - Bus VIP Backend 集成指南

## 概述

`bus_pkg` 提供统一的总线访问抽象层。不同的 bus VIP 后端（APB、AXI、AHB 等）只需实现 `bus_master_handle` 的子类，即可通过 `BUS` Facade 统一访问。

```
test code
  ↓
BUS::master("apb0").write(addr, data)    ← 统一 API
  ↓
bus_master_handle.try_write()             ← 抽象接口
  ↓
tvip_apb_master_bridge.try_write()        ← 具体后端
  ↓
APB bus → DUT
```

## 集成步骤

### 1. 实现 bus_master_handle 子类

继承 `bus_master_handle`，实现 `try_write` 和 `try_read`：

```systemverilog
class my_vip_master_bridge extends bus_master_handle;

  protected my_vip_sequencer m_sequencer;

  function new(string name = "", my_vip_sequencer sqr = null);
    super.new(name);
    m_sequencer = sqr;
  endfunction

  virtual task try_write(
    output bus_status_e   status,
    input  bus_addr_t     addr,
    input  bus_data_t     data,
    input  int unsigned   n_bytes = 0
  );
    my_vip_item item = my_vip_item::type_id::create("item");
    item.addr = addr;
    item.data = data;
    item.dir  = MY_VIP_WRITE;
    // 通过 sequencer 发送 transaction
    item.start(m_sequencer);
    status = item.error ? BUS_ERROR : BUS_OK;
  endtask

  virtual task try_read(
    output bus_status_e   status,
    input  bus_addr_t     addr,
    output bus_data_t     data,
    input  int unsigned   n_bytes = 0
  );
    my_vip_item item = my_vip_item::type_id::create("item");
    item.addr = addr;
    item.dir  = MY_VIP_READ;
    item.start(m_sequencer);
    data   = item.data;
    status = item.error ? BUS_ERROR : BUS_OK;
  endtask

  // burst 不支持时返回 BUS_UNSUPPORTED
  virtual task try_burst_write(...);
    status = BUS_UNSUPPORTED;
  endtask

  virtual task try_burst_read(...);
    status = BUS_UNSUPPORTED;
  endtask

endclass
```

### 2. 创建测试环境

在 env 中实例化 VIP agent 和 bridge，注册到 `BUS` Facade：

```systemverilog
class my_vip_env extends uvm_env;

  my_vip_agent        master_agent;
  my_vip_master_bridge bridge;

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // 创建 bridge，传入 sequencer
    bridge = new(.name("axi0"), .sqr(master_agent.sequencer));

    // 注册到 BUS Facade
    BUS::register("axi0", bridge);
  endfunction

endclass
```

### 3. 在测试中使用

测试代码只依赖 `bus_master_handle`，不关心底层是哪个 VIP：

```systemverilog
class my_test extends uvm_test;
  my_vip_env env;

  task run_phase(uvm_phase phase);
    bus_master_handle mh;
    bus_data_t data;
    bus_status_e status;

    phase.raise_objection(this);

    // 通过 BUS Facade 获取 handle
    mh = BUS::master("axi0");

    // 统一的 write/read API
    mh.write(64'h1000_0000, data, 4);
    mh.read(64'h1000_0000, data, 4);

    // 或使用 try_* 接口检查状态
    mh.try_write(status, 64'h2000_0000, data, 4);
    assert(status == BUS_OK);

    phase.drop_objection(this);
  endtask
endclass
```

### 4. 替换 VIP 后端

只需更换 env 中的 bridge 实现，测试代码无需修改：

```systemverilog
// 项目 A 使用 tvip-apb
BUS::register("master0", tvip_apb_bridge);

// 项目 B 使用 Synopsys AXI SVT
BUS::register("master0", svt_axi_bridge);

// 项目 C 使用自定义 VIP
BUS::register("master0", custom_bridge);

// 测试代码完全不变
mh = BUS::master("master0");
mh.write(addr, data, 4);
```

## 宽度处理

`bus_data_t` 是 1024-bit，`bus_addr_t` 是 64-bit。后端 bridge 负责截断/扩展到实际 VIP 宽度：

```systemverilog
// APB 32-bit data
item.data = tvip_apb_data'(data);       // 截断到 32-bit

// 读回时扩展
data = '0;
data = bus_data_t'(item.data);           // 零扩展到 1024-bit
```

## 参考实现

完整示例见 `tests/bus_pkg/tvip_apb/`：

| 文件 | 说明 |
|------|------|
| `tvip_apb_master_bridge.svh` | APB 后端 bridge 实现 |
| `tvip_apb_slave_mem.svh` | APB slave memory model |
| `tvip_apb_env.svh` | 测试环境组装 |
| `../test_bus_apb.sv` | 测试用例 |
