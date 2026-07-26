# 01 — archway_core_pkg — Config 基础设施

**What to build:** 创建 `archway_core_pkg`，实现 `archway_config_base` 基类，提供 config 校验和冻结机制。所有组件的 config 都继承此基类，为后续 bus_pkg、map_pkg、archway_pkg 提供统一的 config 语义基础。

**Blocked by:** None — can start immediately.

**Status:** completed

- [x] 创建 `archway_core_pkg` package
- [x] 实现 `archway_config_base` 基类
- [x] 实现 `validate(ref string errors[$])` pure virtual 方法
- [x] 实现 `freeze()` 方法（设置 `frozen = 1`，子类可扩展）
- [x] 实现 `check_not_frozen(field_name)` helper 方法
- [x] 验证：创建一个测试 config 子类，验证 validate/freeze 机制正常工作
