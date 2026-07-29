# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Agent skills

### Issue tracker

Local markdown files in `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout with `CONTEXT.md` at root and `docs/adr/` for architecture decisions. See `docs/agents/domain.md`.

## Build and test

```bash
# 运行回归测试
make -C run regression

# 编译单个测试
make -C run compile PKG=bus_pkg TEST=test_bus_pkg_full

# 运行单个测试
make -C run run PKG=bus_pkg TEST=test_bus_pkg_full

# 清理仿真文件
make -C run clean
```

## File placement rules

1. **源代码** → `src/<package_name>/`
2. **测试代码** → `tests/<package_name>/`
3. **测试配置** → `tests/cfg/`
4. **设计规格** → `docs/spec/`
5. **架构决策** → `docs/adr/`
6. **问题记录** → `docs/issues/`
7. **仿真输出** → `run/sim/`（自动 gitignore）

## Dependencies

使用 Zephyr West 管理外部依赖。

```bash
west init -l .
west update
```

| 依赖 | 路径 | 用途 |
|------|------|------|
| sv_serde | `lib/sv_serde` | YAML 序列化（核心依赖） |
| tue | `tests/bus_pkg/lib/tue` | UVM 扩展库（tvip-apb 依赖） |
| tvip-apb | `tests/bus_pkg/lib/tvip-apb` | APB VIP（bus_pkg 测试用） |
