# Archway 通用 SoC 验证框架说明摘要

## 1. 这套框架要解决什么问题

Archway 旨在把 SoC 验证里每个项目都会反复遇到的共性需求抽象成可复用组件，让不同项目、不同团队、不同层级的验证代码保持一致的风格、接口和装配方式。

它不是只为单个项目定制的一套工具，而是一个可长期演进的通用验证框架。

### 价值

- **统一风格**：同类问题使用同类接口和组织方式，便于上手和阅读。
- **加快开发**：把重复建设的 bus、map、config、装配、校验等能力沉淀到框架中。
- **便于协作**：bus、map、crg、iomux、power 等子组件可以由不同人并行开发。
- **便于扩展**：v1 先覆盖最小公共能力，后续可以逐步增加组件和特性。
- **减少项目特例污染**：把通用能力放进 common framework，把项目差异留在项目层。

## 2. 基本框架思路

Archway 的核心思路是：

1. 把 SoC 验证中的共性资源抽象为独立 package。
2. 每个 package 只负责一种能力，避免跨包耦合。
3. 各组件使用自己的 YAML 配置，先生成 config 对象，再做校验和冻结。
4. `archway_env` 负责显式装配、依赖排序和生命周期管理。
5. 项目层创建真实 UVM agent，并注册成框架可访问的资源。
6. 测试和 sequence 只使用稳定 Facade，不直接关心项目内部实现。

## 3. v1 的核心分层

### 3.1 `bus_pkg`

负责总线访问能力。

提供：
- `BUS`
- `bus_master_handle`
- `bus_slave_handle`
- master / slave 注册与获取
- master / slave 枚举
- 单次 read/write API
- burst API

不提供：
- memory map 解析
- target 语义
- YAML 解析
- RAL 建模
- 协议字段级暴露

### 3.2 `map_pkg`

负责 memory map 能力。

提供：
- `MAP`
- `map_view`
- `map_region`
- view 注册与获取
- target 到 base / region 的查询

不提供：
- bus 执行
- 协议转换
- 最终地址访问

### 3.3 `archway_core_pkg`

只放最基础、最稳定的公共类型。

v1 只放：
- `archway_config_base`

### 3.4 `archway_pkg`

框架顶层组装 package，负责统一装配和生命周期控制。

它不是组合访问层，也不是业务逻辑层。

v1 包含：
- `archway_env`：统一装配容器，负责依赖拓扑排序、config 校验/freeze、组件 enable/register
- `ARCHWAY` Facade：框架级资源入口，用于注册、查询和获取框架级资源

职责包括：
- 接收项目 env 的组件启用信息
- 接收项目创建的组件 env
- 做前置校验
- 做依赖拓扑排序
- 冻结 config
- 统一完成装配
- 在 `connect_phase` 检查基类流程是否被正确执行

## 4. 运行时结构

推荐的运行时结构如下：

```text
tb_top
  ↓ interface 实例化和 vif 挂载
uvm_test
  ↓ 例化项目 env
act_env extends archway_env
  ↓ configure_archway()
  ↓ enable_bus / enable_map / enable_crg
  ↓ 创建 act_archway_bus_env / act_archway_map_env
  ↓ register_bus_env / register_map_env
act_archway_bus_env extends archway_bus_env
  ↓ 创建项目实际 bus agent / adapter / handle，并注册到 BUS
真实 bus agent / sequencer / monitor / checker
```

### 关键点

- `tb_top` 负责物理 interface。
- 项目 env 负责选择启用哪些能力。
- 项目组件 env 负责创建真实 agent 和后端实现。
- `archway_env` 负责统一装配和校验。
- 框架不强制做 target-relative 组合 Facade。

## 5. 配置与校验

### 5.1 配置形式

- 第一版只支持 YAML。
- 但不是一份全局大 YAML。
- 各子组件自己定义自己的 YAML 格式。
- 后续如需 IP-XACT，可先在框架外转换成对应组件 YAML。

### 5.2 config 约束

- config 继承 `archway_config_base`。
- config 以纯数据为主。
- 可以带少量自校验方法。
- 不允许创建 agent、注册 Facade、启动 sequence 或访问 DUT。

### 5.3 校验方式

- 组件 config 提供 `validate(ref string errors[$])`。
- 组件自己追加错误信息。
- `archway_env` 汇总后统一处理。
- `freeze()` 由基类提供默认实现，子类可扩展。

## 6. 命名与访问规则

### 6.1 Facade 命名

- `BUS`
- `MAP`
- `ARCHWAY`

### 6.2 资源 API 统一规则

- `has_<resource>()`：探测资源是否存在
- `<resource>()`：获取资源，找不到时 fatal
- `get_<resource>_names()`：枚举资源名称

### 6.3 命名约定

- 框架内部实现细节成员变量使用 `m_` 前缀。
- 用户可见稳定字段不加前缀。
- 多 env 场景下，注册名和 instance name 建议带项目 / 芯片前缀。
- 作用域分隔符固定为 `.`，但 v1 不做 scope tree 解析，只把完整名字当作 string key。

## 7. 开发协作方式

Archway 适合多人协作开发，因为各能力包边界清晰：

- 一个人做 bus
- 一个人做 map
- 一个人做 crg
- 一个人做 iomux
- 一个人做 power

只要遵守统一的：
- 命名规范
- YAML 约定
- config 约定
- 装配约定
- Facade 访问约定

最后就可以汇入同一个 Archway 运行时环境。

## 8. v1 非目标

第一版不做：

- 目标级组合 Facade
- 复杂 scope 解析
- 自动扫描目录
- 全局大 YAML
- 动态 remap
- 完整 IP-XACT 语义导入
- RAL frontdoor 集成
- 把项目特例塞进 common package

## 9. 适合合作方理解的一句话

Archway 的目标，是把 SoC 验证中反复出现的通用问题抽成稳定、可插拔、可协作的框架能力，让不同项目在保持一致风格的前提下，更快地搭起环境、接入资源、开展验证。

