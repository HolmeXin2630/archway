# 04 — map_pkg — Memory Map 能力

**What to build:** 创建 `map_pkg`，实现 `MAP` Facade、`map_view` 和 `map_region`，提供 view 注册/查询能力和 target 到 base/region 的映射。让项目可以通过 `MAP::view("name").get_region("target", region)` 查询 memory map 信息。

**Blocked by:** 01 — archway_core_pkg

**Status:** ready-for-agent

- [ ] 创建 `map_pkg` package
- [ ] 定义公共类型：`map_addr_t`、`map_status_e`
- [ ] 实现 `map_region` 类（target、base、size）
- [ ] 实现 `map_view` 类：`add_region()`、`get_region()`、`has_region()`、`get_base()`
- [ ] 实现 `MAP` Facade：`register_view()`、`has_view()`、`view()`
- [ ] 实现 `get_view_names()` 枚举方法
- [ ] 支持作用域写法（如 `chip0.core0`），v1 按 string key 处理
- [ ] 验证：创建测试 view，验证 view 注册/查询 + region 映射流程
