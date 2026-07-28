# Archway - 通用 SoC 验证框架

## 项目概述

Archway 是一个通用的 SoC 验证框架，旨在把 SoC 验证中每个项目都会反复遇到的共性需求抽象成可复用组件。

## 目录结构

```
sv_proj/                          # West 工作区根目录
├── archway/                      # 本项目（manifest 仓库）
│   ├── src/                      # 源代码
│   ├── tb/                       # 测试代码
│   ├── docs/                     # 文档
│   ├── west.yml                  # West manifest 文件
│   └── Makefile                  # 构建脚本
├── lib/                          # 依赖库（由 west 管理）
│   └── sv_serde/                 # SystemVerilog JSON/YAML/INI 处理库
└── ...                           # 其他项目
```

## 快速开始

### 安装和初始化

```bash
# 安装 west
pip install west

# 克隆并初始化
git clone https://github.com/HolmeXin2630/archway.git
cd .. && west init -l archway && west update
```

### 更新依赖

```bash
west update    # 更新所有依赖
west list      # 查看依赖状态
```

### 编译和运行

```bash
cd archway
make all SIM=vcs      # 编译并运行测试
make clean            # 清理生成文件
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

本项目使用 [West](https://docs.zephyrproject.org/latest/develop/west/index.html) 管理依赖库。

### sv_serde

SystemVerilog JSON/YAML/INI 处理库，提供统一的 API 进行数据序列化和反序列化。

- **仓库地址**: https://github.com/HolmeXin2630/sv_serde
- **功能**: JSON、YAML、INI 解析和生成，统一 API，不可变语义

**使用示例**:

```systemverilog
import sv_yaml_pkg::*;

sv_yaml y = sv_yaml::parse("name: Alice\nage: 30");
string name = y.get("name").as_string();  // "Alice"
int age = y.get("age").as_int();          // 30
```

## 已知问题

- sv_serde 地址解析符号扩展问题 - 当地址值超过 0x7FFFFFFF 时，as_int() 会返回符号扩展的值。详见 [known_issues.md](docs/known_issues.md)
