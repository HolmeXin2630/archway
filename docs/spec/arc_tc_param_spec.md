# ARC_PARAM 内网从零开发 Spec

本文档是内网唯一可复制材料，用于从零复现 `ARC_PARAM`。内网不能复制外网已有源码；必须按本文档先写测试，再实现。

## 1. 目标

`ARC_PARAM` 是 Archway 的 testcase 参数注入组件：从 `.tc` 文件读取 `-ARC_PARAM:<object>.<path>=<value>`，注入到 SystemVerilog config object。

目标用户流程：

```systemverilog
import arc_param_pkg::*;

ARC_PARAM_DB.clear();
ARC_PARAM_DB.parse_file("tests/arc_param_pkg/case.tc");
cfg = new("tch0_tap0_opt");
cfg.load_arc_param();
ARC_PARAM_DB.check_unused();
ARC_PARAM_DB.summary();
```

`.tc` 示例：

```text
-ARC_PARAM:tch0_tap0_opt.run_num=1
-ARC_PARAM:tch0_tap0_opt.mode="fast"
-ARC_PARAM:tch0_tap0_opt.enabled=1
-ARC_PARAM:tch0_tap0_opt.ratio=0.75
-ARC_PARAM:tch0_tap0_opt.run_list[0]=10
-ARC_PARAM:tch0_tap0_opt.sub_cfg.delay=5
```

## 2. 工程组织

Archway 中的 package 采用 `src/<package>/<package>.sv` 组织；测试采用 `tests/<package>/` 组织。项目导入 ARC_PARAM 时，compile option 添加：

```text
+incdir+archway/src/arc_param_pkg
```

不要把所有类放进一个 package 文件。必须使用 `*_pkg.sv` 包壳 + `` `include`` `.svh` 文件的组织方式。

必须创建：

```text
archway/src/arc_param_pkg/arc_param_pkg.sv
archway/src/arc_param_pkg/arc_param/arc_param_item.svh
archway/src/arc_param_pkg/arc_param/arc_param_object.svh
archway/src/arc_param_pkg/arc_param/arc_param_string_utils.svh
archway/src/arc_param_pkg/arc_param/arc_param_codec.svh
archway/src/arc_param_pkg/arc_param/arc_param_list_utils.svh
archway/src/arc_param_pkg/arc_param/arc_param_path_utils.svh
archway/src/arc_param_pkg/arc_param/arc_param_db.svh
archway/src/arc_param_pkg/arc_param/arc_param_macros.svh
archway/tests/arc_param_pkg/case.tc
archway/tests/arc_param_pkg/bad_case.tc
archway/tests/arc_param_pkg/test_arc_param_*.sv
archway/run/Makefile
```

`src/arc_param_pkg/arc_param_pkg.sv` 结构固定为：

```systemverilog
package arc_param_pkg;
  typedef class arc_param_db;
  `include "arc_param/arc_param_item.svh"
  `include "arc_param/arc_param_object.svh"
  `include "arc_param/arc_param_string_utils.svh"
  `include "arc_param/arc_param_codec.svh"
  `include "arc_param/arc_param_list_utils.svh"
  `include "arc_param/arc_param_path_utils.svh"
  `include "arc_param/arc_param_db.svh"
  arc_param_db ARC_PARAM_DB = arc_param_db::get();
  `include "arc_param/arc_param_macros.svh"
endpackage
```

约束：

- `ARC_PARAM_DB` 是由 `arc_param_db::get()` 返回的唯一全局 db 实例名。
- `arc_param_db` 构造函数为 `local`；调用方不得自行 `new` 或替换该实例。
- `arc_param_object::load_arc_param()` 调用 `ARC_PARAM_DB.load(this)`。
- 字段宏只保留小写形式，不提供 `ARC_PARAM_INT` 等大写别名。
- `arc_param_pkg` 是纯 SystemVerilog 工具包，不 import `uvm_pkg`，也不承担 UVM phase 或 plusarg 自动入口职责。

## 3. 测试先行顺序

每一步先写测试，确认失败，再写最小实现让测试通过。

### T0 package 编译

测试：`test_arc_param_phase1.sv` 最小 import package 后 `$finish`。

达标：

- [ ] `src/arc_param_pkg/arc_param_pkg.sv` 可编译。
- [ ] `import arc_param_pkg::*;` 可用。
- [ ] `+incdir+archway/src/arc_param_pkg` 可找到所有 include。
- [ ] package 文件只包含 package、typedef、include、`ARC_PARAM_DB`。

### T1 codec

测试：`test_arc_param_codec.sv`。

必须覆盖：

- [ ] decimal：`123`。
- [ ] signed：`-123`。
- [ ] underscore：`1_000`。
- [ ] `0x10`、`0b1010`、`0o17`。
- [ ] SV literal：`32'hff`、`'b1010`、`'o17`、`'d10`。
- [ ] int/longint/longint unsigned 转换。
- [ ] real：`0.75`。
- [ ] string unquote：`"fast"` -> `fast`。

实现要求：

- 不要靠 `$sscanf` 一次性解析不带位宽的 SV base literal。
- 显式拆 base/digit，并用 `longint unsigned` 手动累加。
- invalid sentinel 用 `64'hffff_ffff_ffff_ffff`，不要用 `-1`。
- 使用显式类型转换，避免数值解析中的非预期扩展或截断。

### T2 tokenizer/list

测试：`test_arc_param_tokenizer.sv`。

必须覆盖：

- [ ] strip 一层 `{}`：`{1,2,3}` -> `1,2,3`。
- [ ] 顶层逗号拆分：`1,2,3` -> 3 项。
- [ ] 字符串内逗号不拆：`"a,b",c` -> 2 项。
- [ ] brace 内逗号不拆：`{1,2},3` -> 2 项。
- [ ] 空列表 `{}` 合法，size 为 0。

### T3 Phase 1 注入

测试：`test_arc_param_phase1.sv` + `case.tc`。

`case.tc` 至少包含：

```text
-ARC_PARAM:tch0_tap0_opt.run_num=1
-ARC_PARAM:tch0_tap0_opt.start_ms=0
-ARC_PARAM:tch0_tap0_opt.end_ms=80
-ARC_PARAM:tch0_tap0_opt.mode="fast"
-ARC_PARAM:tch0_tap0_opt.enabled=1
-ARC_PARAM:tch0_tap0_opt.ratio=0.75
-ARC_PARAM:tch0_tap0_opt.sat_type=GLO_L10F
-ARC_PARAM:tch0_tap0_opt.run_list[0]=10
-ARC_PARAM:tch0_tap0_opt.run_list[1]=20
-ARC_PARAM:tch0_tap0_opt.sub_cfg.delay=5
-ARC_PARAM:tch0_tap0_opt.unknown_field=99
```

测试 class 必须覆盖父 config、子 config、enum parse function、小写宏绑定。达标：

- [ ] `run_num/start_ms/end_ms/mode/enabled/ratio/sat_type` 注入正确。
- [ ] `run_list[0]`、`run_list[1]` 注入正确。
- [ ] `sub_cfg.delay` 注入正确。
- [ ] 用户不手写 `apply_arc_param()`，由宏生成。
- [ ] unknown field warning 一次，不 fatal。

### T4 array/queue 整体赋值

测试：`test_arc_param_array_assign.sv`，直接调用 `apply_arc_param()`。

达标：

- [ ] `arc_param_queue_int/real/string` 支持 `{...}` 整体赋值。
- [ ] `arc_param_array_int/real/string` 支持 dynamic array 整体赋值。
- [ ] queue 整体赋值先清空再重建。
- [ ] dynamic array 整体赋值重新 `new[size]`。
- [ ] string list 中的逗号不被误拆。

### T5 associative array / object queue

测试：`test_arc_param_assoc_object.sv`。

达标：

- [ ] string-key assoc：`weight["tap0"]`、`alias_name["tap0"]`、`ratio["tap0"]`。
- [ ] `arc_param_assoc_int/string/real` 可用。
- [ ] `arc_param_queue_object_new` 自动扩展 queue，并用 `new()` 默认构造对象。
- [ ] `arc_param_queue_object` 支持用户预先创建对象。
- [ ] object queue 负数 index 报 error。
- [ ] object queue 缺少子字段路径报 error。

### T6 diagnostics

测试：`test_arc_param_diagnostics.sv`。

达标：

- [ ] `total_count > 0`。
- [ ] `used_count > 0`。
- [ ] `unused_count > 0`。
- [ ] `unknown_count > 0`。
- [ ] `warning_count > 0`。
- [ ] 非 strict 模式 `error_count == 0`。
- [ ] `summary()` 打印 total/used/unused/unknown/warnings/errors。
- [ ] 重复 `load_arc_param()` 不重复增加 unknown warning。
- [ ] 重复 `check_unused()` 不重复增加 unused warning。

### T7 bad line / negative index

测试：`test_arc_param_bad_line.sv`、`test_arc_param_negative.sv`。

达标：

- [ ] bad line 报 error 并 `error_count++`，不崩溃。
- [ ] `run_list[-1]` 报 error。
- [ ] `lanes[-1].run_num` 报 error。
- [ ] 负数 index 不改变目标 queue。

## 4. 必须实现的 API

### 4.1 class / object

`arc_param_item` 字段：

```systemverilog
string obj_name, path, value, file;
int line_no;
bit used, matched, unknown_reported, unused_reported;
```

`arc_param_object` API：

```systemverilog
function new(string name = "");
function string get_name();
virtual function bit apply_arc_param(string path, string value); // default return 0
function void load_arc_param(); // calls ARC_PARAM_DB.load(this)
```

`apply_arc_param()` 禁止写成 pure virtual。

### 4.2 utilities

必须实现函数：

```systemverilog
arc_param_find_char
arc_param_starts_with
arc_param_trim
arc_param_unquote
arc_param_strip_underscores
arc_param_lower
arc_param_char_is_base_digit
arc_param_base_digit_value
arc_param_parse_based_digits
arc_param_to_longint_unsigned
arc_param_to_longint
arc_param_to_int
arc_param_to_real
arc_param_find_top_level_char
arc_param_split_top_level
arc_param_strip_outer_braces
arc_param_parse_list_items
arc_param_assign_queue_int/real/string
arc_param_assign_array_int/real/string
arc_param_split_path
arc_param_match_index_tail
arc_param_match_index
arc_param_match_string_key
```

### 4.3 `arc_param_db`

字段：

```systemverilog
arc_param_item items[$];
bit strict_unknown, strict_unused;
int total_count, used_count, unused_count, unknown_count, error_count, warning_count;
```

API：

```systemverilog
static function arc_param_db get()
clear()
set_strict(bit strict_unknown_en = 1, bit strict_unused_en = 1)
parse_file(string file)
parse_line(string line, string file = "", int line_no = 0)
load(arc_param_object obj)
check_unused()
summary()
```

行为：

- [ ] `clear()` 清空 items、计数、strict flag。
- [ ] `parse_file()` 用 `$fopen/$fgets` 逐行读文件。
- [ ] 文件打不开 `$error` 且 `error_count++`。
- [ ] `parse_line()` 忽略空行、整行注释、非 `-ARC_PARAM:` 行。
- [ ] 合法行生成 item，`total_count++`。
- [ ] bad line `$error`，`error_count++`。
- [ ] `load()` 只处理 object name 匹配的 item。
- [ ] 注入成功第一次设置 used 时 `used_count++`。
- [ ] unknown field warning 只报一次；strict unknown 额外 error。
- [ ] `check_unused()` warning 只报一次；strict unused 额外 error。

## 5. 必须实现的宏

只实现小写宏：

```systemverilog
`arc_param_begin
`arc_param_end
`arc_param_int(VAR)
`arc_param_bit(VAR)
`arc_param_string(VAR)
`arc_param_real(VAR)
`arc_param_enum(VAR, PARSE_FUNC)
`arc_param_queue_int(VAR)
`arc_param_queue_real(VAR)
`arc_param_queue_string(VAR)
`arc_param_array_int(VAR)
`arc_param_array_real(VAR)
`arc_param_array_string(VAR)
`arc_param_assoc_int(VAR)
`arc_param_assoc_real(VAR)
`arc_param_assoc_string(VAR)
`arc_param_queue_object(PATH_NAME, HANDLE_Q)
`arc_param_queue_object_new(PATH_NAME, HANDLE_Q, TYPE)
`arc_param_object(PATH_NAME, HANDLE)
```

宏要求：

- [ ] `arc_param_begin/end` 生成 `apply_arc_param(path,value)`。
- [ ] 标量宏 path 完全匹配字段名。
- [ ] `arc_param_bit` 使用 `(arc_param_to_int(value) != 0)`。
- [ ] queue 宏支持整体赋值和 `[index]` 赋值。
- [ ] assoc 宏只支持 `["key"]` string key。
- [ ] object 宏转发子路径给子对象。
- [ ] object queue 宏转发 index tail 给对应对象。

## 6. tc 语法

格式：

```text
-ARC_PARAM:<object_name>.<field_path>=<value>
```

规则：

- [ ] 空行忽略。
- [ ] `#` 开头整行注释忽略。
- [ ] 非 `-ARC_PARAM:` 行忽略。
- [ ] 第一个 `.` 前是 object name。
- [ ] 第一个 `.` 到第一个 `=` 之间是 field path。
- [ ] 第一个 `=` 后是 value。
- [ ] 三段 trim。
- [ ] 当前不支持行尾注释。

value 必须支持：int、real、string、bit、enum、hex/bin/oct/SV literal、`{...}` list。

当前不支持：行尾注释、完整字符串 escape、多维数组、assoc 整体赋值、bit vector 截断诊断、plusarg 自动入口、schema/binder/registry、UVM phase 自动集成。

## 7. VCS 回归

在现有 `run/Makefile` 中增加 `arc_param_pkg` 的 package 定义与 include directory，并增加 `arc_param_regression` target。该 target 逐个编译、运行 ARC_PARAM 测试 top，复用现有 `run/sim/` 作为 VCS 生成目录和日志目录。

- [ ] 从仓库根目录通过 `make -C run arc_param_regression SIM=vcs` 运行。
- [ ] 使用 `+incdir+$(ROOT_DIR)/src/arc_param_pkg`；项目侧等价为 `+incdir+archway/src/arc_param_pkg`。
- [ ] 编译入口是 `src/arc_param_pkg/arc_param_pkg.sv`。
- [ ] 逐个运行 `tests/arc_param_pkg/test_arc_param_*.sv` top。
- [ ] 至少运行 T0–T7 所有测试。
- [ ] 全部通过后打印 `ARC_PARAM VCS regression PASS`。

VCS 编译要求：开启 SystemVerilog，添加 `+incdir+archway/src/arc_param_pkg`，编译 `archway/src/arc_param_pkg/arc_param_pkg.sv`，再编译目标 testbench，`import arc_param_pkg::*;`。

## 8. 总验收 checklist

文件结构：

- [ ] `src/arc_param_pkg/arc_param_pkg.sv` 存在，且只做 package/include/global db。
- [ ] `src/arc_param_pkg/arc_param/*.svh` 拆分存在。
- [ ] 没有把所有 class 放在一个 package 文件中。
- [ ] `+incdir+archway/src/arc_param_pkg` 能找到 package 和 include。

API：

- [ ] `arc_param_object`、`arc_param_db`、`ARC_PARAM_DB` 存在。
- [ ] `apply_arc_param()` 是普通 virtual 默认返回 0。
- [ ] `arc_param_db::get()` 返回唯一实例，且调用方不能自行构造 `arc_param_db`。
- [ ] 只有小写字段宏，没有 `ARC_PARAM_INT` 等大写别名。

功能：

- [ ] parse tc 文件、注入标量、queue、array、assoc、nested object、object queue。
- [ ] codec 支持 decimal/signed/underscore/base literal/real/string。
- [ ] unknown、unused、bad line、negative index 有诊断和计数。
- [ ] strict unknown/unused 可升级 error。
- [ ] 重复 load/check 不重复刷 warning。

测试：

- [ ] 测试先于实现编写。
- [ ] T0–T7 全部通过。
- [ ] VCS 一键回归通过。
- [ ] VCS 至少跑通 phase1、codec、diagnostics。

## 9. 禁止回退项

- [ ] 不用 pure virtual。
- [ ] bit 赋值不用 int 直接截断，必须比较非零。
- [ ] numeric codec 不要退回 `$sscanf` 一把梭。
- [ ] unsigned invalid sentinel 不用 `-1`。
- [ ] 保留 `matched/unknown_reported/unused_reported`。
- [ ] 不恢复任何 `ARC_PARAM_*` 字段宏别名。
- [ ] 不实现 plusarg、schema/binder/registry、多维数组等非目标能力，除非后续单独立项。

## 10. 给内网 AI 的执行提示

1. 只能依据本文档从零实现，不要假设已有源码。
2. 先建文件树，再写测试，再实现。
3. 每个功能先有失败测试。
4. package 文件只写 include 和全局实例。
5. 编译入口是 `src/arc_param_pkg/arc_param_pkg.sv`。
6. include 路径按 `+incdir+archway/src/arc_param_pkg` 设计。
7. 全局 db 叫 `ARC_PARAM_DB`。
8. 使用 `arc_param_db::get()` 获取唯一的 `ARC_PARAM_DB` 实例；调用方不得自行构造 db。
9. 只用小写字段宏。
10. 每通过一个测试就更新 checklist。
