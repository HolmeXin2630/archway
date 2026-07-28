# Archway - 通用 SoC 验证框架

## 项目概述

Archway 是一个通用的 SoC 验证框架，旨在把 SoC 验证中每个项目都会反复遇到的共性需求抽象成可复用组件。

## 目录结构

```
archway/
├── src/                          # 源代码
│   ├── archway_core_pkg/         # 核心基础类型
│   │   ├── archway_core_pkg.sv
│   │   └── archway_config_base.svh
│   ├── bus_pkg/                  # 总线访问能力（待实现）
│   ├── map_pkg/                  # Memory Map 能力（待实现）
│   └── archway_pkg/              # 框架顶层组装（待实现）
├── tb/                           # 测试代码
│   └── archway_core_pkg/
│       └── test_archway_config_base.sv
├── lib/                          # 依赖库（Git Submodule）
│   └── sv_serde/                 # SystemVerilog JSON/YAML/INI 处理库
│       ├── sv_serde/             # 核心序列化库
│       ├── sv_json/              # JSON 支持
│       ├── sv_yaml/              # YAML 支持
│       └── sv_ini/               # INI 支持
├── docs/                         # 文档
│   ├── soc_framework_v1.md
│   ├── module_bus_map.md
│   ├── adr/                      # 架构决策记录
│   └── agents/                   # Agent skills 配置
├── .scratch/                     # Issue tracker
│   └── archway-v1/
│       └── issues/               # Tickets
├── .gitmodules                   # Git Submodule 配置
├── CLAUDE.md                     # Agent skills 配置
├── CONTEXT.md                    # 项目上下文
├── Makefile                      # 构建脚本
└── README.md                     # 本文件
```

## 快速开始

### 克隆仓库

本项目使用 Git Submodule 管理依赖库。克隆时需要初始化 submodule：

```bash
# 方式 1：递归克隆（推荐）
git clone --recurse-submodules https://github.com/HolmeXin2630/archway.git

# 方式 2：克隆后手动初始化
git clone https://github.com/HolmeXin2630/archway.git
cd archway
git submodule init
git submodule update
```

### 更新依赖

```bash
# 更新 sv_serde 到最新版本
git submodule update --remote lib/sv_serde

# 提交更新
git add lib/sv_serde
git commit -m "chore: update sv_serde submodule"
```

### 编译和运行测试

```bash
# 编译并运行所有测试
make all SIM=vcs

# 只编译
make compile SIM=vcs

# 只运行
make run SIM=vcs

# 清理生成文件
make clean
```

### 支持的仿真器

- `vcs` - Synopsys VCS
- `xcelium` - Cadence Xcelium
- `questa` - Siemens Questa

## Package 结构

### `archway_core_pkg`
核心基础类型，包含：
- `archway_config_base`：所有 config 的基类，提供 validate/freeze 语义

### `bus_pkg`（待实现）
总线访问能力，包含：
- `BUS` Facade
- `bus_master_handle` / `bus_slave_handle`

### `map_pkg`（待实现）
Memory Map 能力，包含：
- `MAP` Facade
- `map_view` / `map_region`

### `archway_pkg`（待实现）
框架顶层组装，包含：
- `archway_env`：统一装配容器
- `ARCHWAY` Facade：框架级资源入口

## 相关文档

- [框架说明摘要](docs/soc_framework_v1.md)
- [BUS/MAP 详细设计](docs/module_bus_map.md)
- [项目上下文](CONTEXT.md)
- [已知问题](docs/known_issues.md)

## 依赖库

本项目依赖以下库（通过 Git Submodule 管理）：

### sv_serde

SystemVerilog JSON/YAML/INI 处理库，提供统一的 API 进行数据序列化和反序列化。

- **仓库地址**: https://github.com/HolmeXin2630/sv_serde
- **功能**:
  - JSON 解析和生成（基于 nlohmann/json）
  - YAML 解析和生成（基于 rapidyaml）
  - INI 文件解析
  - 统一的 API 接口
  - 不可变语义（所有修改返回新对象）

**使用示例**:

```systemverilog
import sv_yaml_pkg::*;

// 解析 YAML
sv_yaml y = sv_yaml::parse("name: Alice\nage: 30");

// 查询
string name = y.get("name").as_string();  // "Alice"
int age = y.get("age").as_int();          // 30

// 修改（返回新对象）
sv_yaml updated = y.set("name", sv_yaml::from_string("Bob"));
```

## 已知问题

- sv_serde 地址解析符号扩展问题 - 当地址值超过 0x7FFFFFFF 时，as_int() 会返回符号扩展的值。详见 [known_issues.md](docs/known_issues.md)
