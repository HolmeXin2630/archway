# 02 — bus_pkg — 核心总线访问

**What to build:** 创建 `bus_pkg`，实现 `BUS` Facade 和 `bus_master_handle`，提供 master 注册/获取/枚举能力，以及单次 read/write API。让项目可以通过 `BUS::master("name")` 获取不可变 handle 并进行总线访问。

**Blocked by:** 01 — archway_core_pkg

**Status:** ready-for-agent

- [ ] 创建 `bus_pkg` package
- [ ] 定义公共类型：`bus_addr_t`、`bus_data_t`、`bus_status_e`、`bus_burst_kind_e`
- [ ] 实现 `bus_master_handle` 基类（extends uvm_object）
- [ ] 实现主接口：`write()`、`read()`（失败时 uvm_error）
- [ ] 实现检查接口：`try_write()`、`try_read()`（返回 status）
- [ ] 实现 `BUS` Facade：`register()`、`has_master()`、`master()`
- [ ] 实现 `get_master_names()` 枚举方法
- [ ] 验证：创建测试 master handle，验证注册/获取/单次读写流程
