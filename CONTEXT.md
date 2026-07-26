# Archway - 通用 SoC 验证框架

## 项目概述

Archway 是一个通用的 SoC 验证框架，旨在把 SoC 验证中每个项目都会反复遇到的共性需求抽象成可复用组件，让不同项目、不同团队、不同层级的验证代码保持一致的风格、接口和装配方式。

## 核心价值

- **统一风格**：同类问题使用同类接口和组织方式，便于上手和阅读
- **加快开发**：把重复建设的 bus、map、config、装配、校验等能力沉淀到框架中
- **便于协作**：bus、map、crg、iomux、power 等子组件可以由不同人并行开发
- **便于扩展**：v1 先覆盖最小公共能力，后续可以逐步增加组件和特性
- **减少项目特例污染**：把通用能力放进 common framework，把项目差异留在项目层

## 技术栈

- **语言**：SystemVerilog/UVM
- **配置格式**：YAML
- **目标平台**：SoC 验证环境

## 核心分层（v1）

### 1. `bus_pkg`
负责总线访问能力，提供：
- `BUS` Facade
- `bus_master_handle` / `bus_slave_handle`
- master / slave 注册与获取
- 单次 read/write API
- burst API

### 2. `map_pkg`
负责 memory map 能力，提供：
- `MAP` Facade
- `map_view` / `map_region`
- view 注册与获取
- target 到 base / region 的查询

### 3. `archway_core_pkg`
只放最基础、最稳定的公共类型：
- `archway_config_base`

### 4. `archway_pkg`
框架顶层组装 package，负责统一装配和生命周期控制：
- `archway_env`：统一装配容器
- `ARCHWAY` Facade：框架级资源入口
- 接收项目 env 的组件启用信息
- 接收项目创建的组件 env
- 做前置校验
- 做依赖拓扑排序
- 冻结 config
- 统一完成装配

## 设计原则

1. 常用访问路径要简单
2. 不要使用可变的全局当前 master
3. `bus_pkg` 和 `map_pkg` 必须彼此独立
4. 项目差异通过初始化阶段注册进去，而不是写死在 common package 里
5. Facade 只保存资源索引，不保存当前选择状态
6. `build_phase` 开始后，组件 config 冻结不可改
7. 装配顺序按显式依赖关系做拓扑排序

## 命名约定

- Facade 命名：`BUS`、`MAP`、`ARCHWAY`
- 资源 API：`has_<resource>()`、`<resource>()`、`get_<resource>_names()`
- 框架内部成员变量使用 `m_` 前缀
- 作用域分隔符固定为 `.`

## v1 非目标

- 目标级组合 Facade
- 复杂 scope 解析
- 自动扫描目录
- 全局大 YAML
- 动态 remap
- 完整 IP-XACT 语义导入
- RAL frontdoor 集成

## 相关文档

- 框架说明摘要：`docs/soc_framework_v1.md`
- BUS/MAP 详细设计：`docs/module_bus_map.md`
