# 05 — archway_pkg — 框架顶层组装

**What to build:** 创建 `archway_pkg`，实现 `archway_env` 基类和 `ARCHWAY` Facade，提供统一装配容器和框架级资源入口。让项目可以通过继承 `archway_env` 并调用 `enable_bus()`/`enable_map()` 来配置和装配验证环境。

**Blocked by:** 02 — bus_pkg 核心总线访问, 04 — map_pkg

**Status:** completed

- [x] 创建 `archway_pkg` package
- [x] 实现 `archway_env` 基类（extends uvm_env）
- [x] 实现 `configure_archway()` hook 方法供项目重载
- [x] 实现 `enable_bus()`、`enable_map()` helper 方法
- [x] 实现 `register_bus_env()`、`register_map_env()` 注册方法
- [x] 实现 `build_phase` template method：调用 configure_archway() → 加载配置 → 校验 → freeze → 装配
- [x] 实现依赖拓扑排序逻辑
- [x] 实现 `connect_phase` 检查：验证基类流程是否被正确执行
- [x] 实现 `ARCHWAY` Facade：`register_env()`、`has_env()`、`get_env()`
- [x] 验证：创建测试项目 env，继承 archway_env，验证装配流程
