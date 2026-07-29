# Archway 已知问题

## 1. sv_serde 地址解析符号扩展问题 (已修复)

**严重程度：** 高
**影响范围：** 所有超过 0x7FFFFFFF 的地址值解析
**状态：** ✅ 已修复 (sv_serde PR #4 已合并)
**修复日期：** 2026-07-26

**问题描述：**
sv_serde 的 `as_int()` 方法返回 32 位有符号整数 (`int`)，当解析的值超过 2^31-1 (0x7FFFFFFF) 时，会被隐式符号扩展到 64 位，导致地址解析错误。

**重现步骤：**
1. YAML 配置中使用大地址值：
   ```yaml
   views:
     core0:
       regions:
         uart0:
           base: 2147483648  # 0x80000000
           size: 4096
   ```
2. 使用 `sv_yaml::parse_file()` 解析
3. 调用 `as_int()` 获取值
4. 结果是 `0xFFFFFFFF80000000` 而不是 `0x0000000080000000`

**测试验证：**
- 测试文件：`tb/archway_pkg/test_sv_serde_bug.sv`
- 测试结果：
  - 0x80000000 → 0xFFFFFFFF80000000 ❌ (符号扩展)
  - 0x40000000 → 0x0000000040000000 ✓ (无符号扩展)
  - 0x7FFFFFFF → 0x000000007FFFFFFF ✓ (无符号扩展)
  - 0x80000001 → 0xFFFFFFFF80000000 ❌ (符号扩展)

**期望行为：**
as_int() 应该返回 64 位无符号整数，或者提供 `as_uint64()` 方法。

**临时解决方案：**
- 在测试中期望符号扩展后的值（如 `64'hFFFF_FFFF_8000_0000`）
- 或者在 config_loader 中手动处理符号扩展

**对 Archway 的影响：**
- map_pkg 中的 base 地址解析会出错
- 所有使用 sv_serde 解析地址的代码都需要考虑这个问题

**相关文件：**
- `lib/sv_yaml/src/sv_yaml_pkg.sv` - sv_yaml::as_int() 实现
- `src/archway_pkg/config_loader.svh` - YAML 配置加载器
- `tb/archway_pkg/test_sv_serde_bug.sv` - Bug 验证测试

**报告日期：** 2026-07-26
