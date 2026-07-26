# 06 — YAML 配置解析与示例集成

**What to build:** 实现各组件的 YAML 配置加载器，并提供完整的项目初始化示例。让项目可以通过 YAML 文件配置 bus、map 等组件，而不是硬编码注册调用。

**Blocked by:** 05 — archway_pkg 框架顶层组装

**Status:** completed

- [x] 实现 map YAML 解析器：读取 views/regions 配置，生成 map_view 对象
- [x] 实现 bus YAML 解析器（如需要）：读取 master/slave 配置
- [x] 将 YAML 解析器集成到 archway_env 的 build_phase 流程中
- [x] 创建示例 YAML 配置文件（参考 spec 中的示例格式）
- [x] 创建完整项目初始化示例：展示如何继承 archway_env 并配置组件
- [x] 验证：使用 YAML 配置创建完整的验证环境，验证 MAP 查询和 BUS 访问流程
