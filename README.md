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
├── docs/                         # 文档
│   ├── soc_framework_v1.md
│   ├── module_bus_map.md
│   ├── adr/                      # 架构决策记录
│   └── agents/                   # Agent skills 配置
├── .scratch/                     # Issue tracker
│   └── archway-v1/
│       └── issues/               # Tickets
├── CLAUDE.md                     # Agent skills 配置
├── CONTEXT.md                    # 项目上下文
├── Makefile                      # 构建脚本
└── README.md                     # 本文件
```

## 快速开始

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

## 已知问题

- sv_serde 地址解析符号扩展问题 - 当地址值超过 0x7FFFFFFF 时，as_int() 会返回符号扩展的值。详见 [known_issues.md](docs/known_issues.md)
