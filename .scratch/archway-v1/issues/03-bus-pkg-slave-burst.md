# 03 — bus_pkg — Slave 与 Burst 扩展

**What to build:** 扩展 `bus_pkg`，实现 `bus_slave_handle` 和 burst read/write API，提供 slave 注册/枚举能力，以及 burst 访问模式。支持 `BUS::slave("name")` 获取 slave handle 和 `burst_write()`/`burst_read()` 进行批量数据传输。

**Blocked by:** 02 — bus_pkg 核心总线访问

**Status:** ready-for-agent

- [ ] 实现 `bus_slave_handle` 基类（extends uvm_object）
- [ ] 实现 `BUS` Facade 的 slave 相关方法：`register_slave()`、`has_slave()`、`slave()`
- [ ] 实现 `get_slave_names()` 枚举方法
- [ ] 实现 burst 主接口：`burst_write()`、`burst_read()`
- [ ] 实现 burst 检查接口：`try_burst_write()`、`try_burst_read()`
- [ ] 支持 burst 类型：SINGLE、INCR、WRAP、FIXED
- [ ] 验证：创建测试 slave handle，验证 slave 注册/枚举 + burst 读写流程
