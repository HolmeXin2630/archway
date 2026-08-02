# ARC_PARAM testcase 参数组件 Spec

本文档定义 `ARC_PARAM` 的目标使用模型、接口、文件结构、行为和验收条件。实现必须以用户侧 config 的构造流程为中心，而不是要求 config 创建完成后由外部代码再次注入。

## 1. 使用目标

`ARC_PARAM` 从 `.tc` 文件解析：

```text
-ARC_PARAM:<param_name>.<field_path>=<value>
```

其中：

- 顶层 `param_path` 是 config 在 testcase 参数树中的起始绑定路径，例如 `tch0_tap0_opt`。
- `field_path` 是该 config 内允许由 TC 修改的字段路径，例如 `run_num`。
- config 类型通过继承 `arc_param_config` 获得参数身份。
- config 使用小写字段宏声明哪些字段允许由 TC 修改。
- testcase 在创建 config 前将 `.tc` 文件解析到 `ARC_PARAM_DB`。
- 环境保证所有 `parse_file()` / `parse_line()` 在所有 phase 和所有 config `new()` 之前完成。
- config 在自己的 `new()` 末尾调用 `ARC_PARAM_DB.load_tc_param(this)`。
- nested config 的完整 `param_path` 由父节点 sub-config 宏自动派生。
- 任意已绑定 config 节点都可以在 `post_randomize()` 中独立重放自己的 TC 参数。
- 调用方创建 config 后即可直接使用，不再调用额外的 `cfg.load_arc_param()`。
- v1 业务 config 必须直接继承 `arc_param_config`，不支持从另一个业务 config 继续派生。
- 可复用的 config 结构通过成员组合和 nested config 表达，不通过多层业务继承表达。

### 1.1 继承与组合约束

支持：

```systemverilog
class xxx_config extends arc_param_config;
  sub_config sub_cfg;
endclass
```

不支持：

```systemverilog
class common_config extends arc_param_config;
endclass

class xxx_config extends common_config;
endclass
```

禁止多层业务 config 继承的原因是父类构造函数会先于派生类构造函数执行。如果父类在 `new()` 末尾加载 TC 参数，派生类尚未完成默认值和成员初始化；派生类后续初始化可能覆盖已加载的 TC 值。派生类宏生成的 `apply_arc_param()` 也会覆盖父类版本，造成父类字段绑定丢失。

需要复用公共配置时，定义独立的 nested config，并由父 config 使用 `arc_param_sub_config` 或 sub-config queue 宏转发相对路径。

### 1.2 标准用户流程

`.tc` 文件：

```text
-ARC_PARAM:tch0_tap0_opt.run_num=1
-ARC_PARAM:tch0_tap0_opt.mode="fast"
-ARC_PARAM:tch1_tap0_opt.run_num=2
```

config 定义：

```systemverilog
import arc_param_pkg::*;

class tap_config extends arc_param_config;
  rand int run_num = 0;
  string mode    = "normal";
  bit    enabled = 1;

  `arc_param_begin
    `arc_param_int(run_num)
    `arc_param_string(mode)
  `arc_param_end

  function new(string param_path = "");
    super.new(param_path);

    // 派生类的默认值和其他构造工作必须在加载前完成。
    enabled = 1;

    // 必须是构造函数的最后一个配置步骤。
    ARC_PARAM_DB.load_tc_param(this);
  endfunction

  function void post_randomize();
    // TC 值最终优先；随机化后重新应用同一组参数。
    ARC_PARAM_DB.load_tc_param(this);
  endfunction
endclass
```

testcase：

```systemverilog
module test_arc_param_demo;
  import arc_param_pkg::*;

  tap_config tch0_cfg;
  tap_config tch1_cfg;
  tap_config default_cfg;

  initial begin
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_file("tests/arc_param_pkg/tc/real_usage.tc");

    tch0_cfg    = new("tch0_tap0_opt");
    tch1_cfg    = new("tch1_tap0_opt");
    default_cfg = new("tch2_tap0_opt");

    assert(tch0_cfg.run_num == 1);
    assert(tch0_cfg.mode == "fast");
    assert(tch1_cfg.run_num == 2);
    assert(default_cfg.run_num == 0);

    ARC_PARAM_DB.check_unused();
    ARC_PARAM_DB.summary();
    $finish;
  end
endmodule
```

### 1.3 生命周期

顺序固定为：

1. testcase 调用 `ARC_PARAM_DB.clear()`。
2. testcase 调用一次或多次 `ARC_PARAM_DB.parse_file()` / `parse_line()`。
3. testcase 或环境创建各个 config。
4. 顶层 config 的 `new(param_path)` 调用 `super.new(param_path)` 保存起始绑定路径。
5. config 完成默认值、子对象和集合初始化。
6. config 在 `new()` 末尾调用 `ARC_PARAM_DB.load_tc_param(this)`。
7. DB 按 `config.get_param_path()` 筛选 item，再调用宏生成的 `apply_arc_param()`。
8. 所有 config 创建完成后，testcase 调用 `check_unused()` 和 `summary()`。

禁止在 `arc_param_config::new()` 中自动加载参数。基类构造期间派生类尚未完成初始化，自动加载可能被派生类后续默认值覆盖。

`load_tc_param()` 是可重复执行的参数重放操作。config 可以在 `post_randomize()` 中再次调用它，使 TC 值覆盖本次随机化结果。ARC_PARAM 不自动关闭字段的 `rand_mode`，用户负责保证 TC 值与 constraint 的业务一致性。

解析时序是使用方必须满足的前置条件：ARC_PARAM 不维护已构造 config 的订阅表，不在晚解析时自动更新对象，也不要求支持 parse 晚于 config `new()` 的场景。

## 2. 匹配与赋值语义

解析：

```text
-ARC_PARAM:tch0_tap0_opt.run_num=1
```

生成一个 DB item：

```text
param_name = "tch0_tap0_opt"
path       = "run_num"
value      = "1"
```

构造：

```systemverilog
tap_config cfg = new("tch0_tap0_opt");
```

加载：

```text
ARC_PARAM_DB.load_tc_param(cfg)
  -> cfg.get_param_path() == "tch0_tap0_opt"
  -> 选择完整键位于该绑定路径下的 item
  -> cfg.apply_arc_param("run_num", "1")
  -> `arc_param_int(run_num)
  -> cfg.run_num = 1
```

规则：

- 匹配依据是 config 的完整 `param_path`，不是 SystemVerilog 类名。
- 同一种 config 类型可以创建多个实例，各自使用不同的 `param_path`。
- TC 中不存在该 `param_path` 时，config 保留默认值，不报错。
- TC 中存在匹配的 `param_path`，但字段未用宏声明时，报告 unknown field。
- 未使用字段宏声明的成员不能由 TC 修改。

### 2.1 统一 config 节点

所有业务类都直接继承同一个 `arc_param_config`，不区分根类型和子类型：

```systemverilog
class delay_config extends arc_param_config;
  int delay = 0;

  `arc_param_begin
    `arc_param_int(delay)
  `arc_param_end

  function new(string param_path = "");
    super.new(param_path);
    ARC_PARAM_DB.load_tc_param(this);
  endfunction

  function void post_randomize();
    ARC_PARAM_DB.load_tc_param(this);
  endfunction
endclass
```

当 `param_path` 非空时，该实例直接从 DB 加载。当路径为空时，`load_tc_param()` 正常 no-op；对象随后作为 nested config 被父节点宏访问时，父节点为它派生完整路径。

例如：

```text
父节点路径：tch0_tap0_opt
字段路径：  sub_cfg[0]
子节点路径：tch0_tap0_opt.sub_cfg[0]
```

完成绑定后，父节点或 `sub_cfg[0]` 自己调用 `load_tc_param()` 都能重放：

```text
-ARC_PARAM:tch0_tap0_opt.sub_cfg[0].delay=7
```

### 2.2 稳定参数树

config 节点的完整 TC 绑定路径在首次绑定后不可变：

- `bind_param_path()` 从空路径绑定到非空路径时成功。
- 再次绑定到相同路径是合法 no-op。
- 尝试绑定到不同路径时报 error，原路径保持不变。
- 同一个 config handle 不允许同时出现在参数树的多个位置。
- 不同 config handle 可以共享同一个完整 TC 绑定路径，并获得相同的参数重放结果。
- sub-config queue 可以在首次 TC 加载时由 `_new` 宏创建和扩展。
- 首次绑定完成后，不支持移动、交换或删除已绑定的 sub-config queue 元素。
- v1 不追踪 rand sub-config queue 造成的结构变化。

该限制只约束 config 节点的结构和身份，不限制标量或其他可配置字段被随机化；字段仍可通过重复 `load_tc_param()` 恢复 TC 值。

## 3. 工程组织

package 使用 `src/<package>/<package>.sv`，测试使用 `tests/<package>/`。

必须创建：

```text
archway/src/arc_param_pkg/arc_param_pkg.sv
archway/src/arc_param_pkg/README.md
archway/src/arc_param_pkg/arc_param/arc_param_item.svh
archway/src/arc_param_pkg/arc_param/arc_param_config.svh
archway/src/arc_param_pkg/arc_param/arc_param_utils.svh
archway/src/arc_param_pkg/arc_param/arc_param_db.svh
archway/src/arc_param_pkg/arc_param/arc_param_macros.svh
archway/tests/arc_param_pkg/arc_param_test_pkg.sv
archway/tests/arc_param_pkg/config/delay_config.svh
archway/tests/arc_param_pkg/config/lane_config.svh
archway/tests/arc_param_pkg/config/tap_config.svh
archway/tests/arc_param_pkg/tc/real_usage.tc
archway/tests/arc_param_pkg/tc/common.tc
archway/tests/arc_param_pkg/tc/override.tc
archway/tests/arc_param_pkg/tc/diagnostics.tc
archway/tests/arc_param_pkg/tc/invalid.tc
archway/tests/arc_param_pkg/test_arc_param_*_usage.sv
archway/tests/arc_param_pkg/test_arc_param_*_unit.sv
archway/run/Makefile
```

文件规则：

- 一个 class 一个文件。
- `arc_param_utils.svh` 只定义 `arc_param_utils` class，所有工具函数是该 class 内的 static function。
- `arc_param_macros.svh` 只定义宏，不定义 class 或 class 外 function。
- 不创建按函数类别拆分的多个 utils 文件。
- `arc_param_pkg.sv` 只承担 package 壳、前向声明、include 和全局单例句柄。
- `src/arc_param_pkg/README.md` 是面向使用者的集成与使用指南，不能只提供内部 API 清单。

`arc_param_pkg.sv`：

```systemverilog
package arc_param_pkg;
  typedef class arc_param_db;

  typedef enum {
    ARC_PARAM_NOT_MATCHED,
    ARC_PARAM_APPLIED,
    ARC_PARAM_INVALID_VALUE
  } arc_param_apply_result_e;

  `include "arc_param/arc_param_item.svh"
  `include "arc_param/arc_param_config.svh"
  `include "arc_param/arc_param_utils.svh"
  `include "arc_param/arc_param_db.svh"

  arc_param_db ARC_PARAM_DB = arc_param_db::get();

  `include "arc_param/arc_param_macros.svh"
endpackage
```

编译选项：

```text
+incdir+archway/src/arc_param_pkg
```

约束：

- `arc_param_db` 构造函数为 `local`。
- `ARC_PARAM_DB` 是 `arc_param_db::get()` 返回的唯一全局实例。
- 调用方不得 `new arc_param_db`，也不得替换 `ARC_PARAM_DB`。
- package 不 import `uvm_pkg`，不承担 UVM phase 或 plusarg 自动入口。
- 字段宏只提供小写形式。

## 4. 必须实现的 class API

### 4.1 `arc_param_item`

```systemverilog
class arc_param_item;
  string param_name;
  string path;
  string value;
  string file;
  int line_no;
  bit used;
  bit matched;
  bit unknown_reported;
  bit invalid_reported;
  bit unused_reported;
endclass
```

`param_name` 是规范名称。实现和文档不得继续使用含义模糊的 `obj_name`。

### 4.2 `arc_param_config`

```systemverilog
virtual class arc_param_config;
  protected string m_param_path;

  function new(string param_path = "");
  function string get_param_path();
  function void bind_param_path(string param_path);
  function void post_randomize();

  virtual function arc_param_apply_result_e apply_arc_param(
    string path,
    string value
  );
endclass
```

行为：

- `new()` 只保存可选 `param_path`，不得在基类构造期间读取 DB。
- 空 `param_path` 合法，表示尚未直接绑定或尚未挂到父节点。
- `get_param_path()` 返回当前完整 TC 绑定路径。
- `bind_param_path()` 供 sub-config 宏为 nested config 派生完整路径。
- `bind_param_path()` 不允许把已绑定实例改到不同路径。
- 不同实例绑定同一路径是合法的，不建立全局 handle 唯一性约束。
- `apply_arc_param()` 默认返回 `ARC_PARAM_NOT_MATCHED`，不得声明为 pure virtual。
- 派生 config 不手写 `apply_arc_param()`；由 `arc_param_begin/end` 生成。
- `arc_param_config` 不提供含义不清晰的裸 `load_tc_param()`。
- 基类 `post_randomize()` 调用 `ARC_PARAM_DB.load_tc_param(this)`，使任何已绑定节点在随机化后自动重放 TC 值。该 SystemVerilog 内建回调不得显式声明为 `virtual`。
- 业务 config 覆盖 `post_randomize()` 时，必须把 `super.post_randomize()` 放在业务处理之后，保证 TC 最终优先。

业务 override：

```systemverilog
function void post_randomize();
  // 业务 post-randomize 处理
  ...

  // 必须最后调用。
  super.post_randomize();
endfunction
```

赋值结果：

```systemverilog
typedef enum {
  ARC_PARAM_NOT_MATCHED,
  ARC_PARAM_APPLIED,
  ARC_PARAM_INVALID_VALUE
} arc_param_apply_result_e;
```

- `ARC_PARAM_NOT_MATCHED`：没有字段宏识别该相对路径。
- `ARC_PARAM_APPLIED`：字段和值都合法，本次赋值成功。
- `ARC_PARAM_INVALID_VALUE`：字段存在但 value 非法，本次不修改字段。

### 4.3 `arc_param_db`

字段：

```systemverilog
local static arc_param_db m_instance;
arc_param_item items[$];
bit strict_unknown;
bit strict_unused;
int total_count;
int used_count;
int unused_count;
int unknown_count;
int error_count;
int warning_count;
```

API：

```systemverilog
static function arc_param_db get();
function void clear();
function void set_strict(
  bit strict_unknown_en = 1,
  bit strict_unused_en = 1
);
function void parse_file(string file);
function void parse_line(
  string line,
  string file = "",
  int line_no = 0
);
function void load_tc_param(arc_param_config config);
function void check_unused();
function void summary();
function void report_error(string message);
```

`load_tc_param()` 行为：

- null config 报 error 并返回。
- 读取 `config.get_param_path()`。
- config 路径为空时正常返回，不报错。
- 将 item 的 `param_name` 与 `path` 组合成完整 TC 键。
- 只遍历完整 TC 键位于 config 绑定路径之下的 item。
- 传给 `apply_arc_param()` 的是相对于当前 config 绑定路径的剩余字段路径。
- 名称匹配时设置 `matched`。
- 调用 `config.apply_arc_param(relative_path, item.value)`。
- 返回 `ARC_PARAM_APPLIED` 时首次设置 `used` 并增加 `used_count`。
- 返回 `ARC_PARAM_NOT_MATCHED` 时首次报告 unknown field。
- 返回 `ARC_PARAM_INVALID_VALUE` 时不修改字段，并对该 item 首次报告 value error。
- unknown、invalid 和 unused 是互斥的最终诊断类别。
- unknown item 不再额外报告 unused。
- invalid item 不再额外报告 unknown 或 unused。
- 每次调用都重新执行匹配 item 的字段赋值；不得因 item 已经 `used` 而跳过。
- 重复加载同一个 config 不重复增加 used/unknown/invalid/error/warning 计数。
- 同一完整键存在多条 item 时，每次加载都按解析顺序应用，最后解析的值最终生效。

解析与诊断行为：

- `clear()` 清空 items、计数和 strict flag。
- `parse_file()` 使用 `$fopen/$fgets` 逐行读取。
- 文件打不开时 `$error` 且 `error_count++`。
- `parse_line()` 忽略空行、整行注释和非 `-ARC_PARAM:` 行。
- 合法行生成 item 并增加 `total_count`。
- 解析到重复完整键时保留新旧 item，增加一次 `warning_count`，并记录新旧文件和行号。
- bad line 报 error，增加 `error_count`，不生成 item。
- `check_unused()` 只对 `matched == 0` 的 item 报告 unused；不能简单以 `used == 0` 判断。
- `check_unused()` 对每个 unmatched item 只报告一次。
- 非 strict unknown/unused 增加 `warning_count`。
- strict unknown/unused 使用 error 替代 warning：只增加 `error_count`，不同时增加 `warning_count`。
- duplicate key 始终是 warning，不受 unknown/unused strict flag 影响。
- `summary()` 打印 total/used/unused/unknown/warnings/errors。

### 4.4 `arc_param_utils`

所有函数必须定义为 `arc_param_utils` class 内的 static function，并通过类作用域调用：

```systemverilog
arc_param_utils::arc_param_to_int(value)
```

至少实现：

```text
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
arc_param_try_to_longint_unsigned
arc_param_try_to_longint
arc_param_try_to_int
arc_param_try_to_real
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

所有工具函数都使用 `static function`，不使用 `automatic function`。

## 5. 必须实现的字段宏

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
`arc_param_sub_config(VAR)
`arc_param_sub_config_as(PATH_NAME, HANDLE)
`arc_param_sub_config_queue(VAR)
`arc_param_sub_config_queue_as(PATH_NAME, HANDLE_Q)
`arc_param_sub_config_queue_new(VAR, TYPE)
`arc_param_sub_config_queue_new_as(PATH_NAME, HANDLE_Q, TYPE)
```

宏要求：

- `arc_param_begin/end` 生成返回 `arc_param_apply_result_e` 的 `apply_arc_param(path, value)`。
- 标量宏只匹配完整字段名。
- 标量宏先解析到临时变量，解析成功后才修改目标字段。
- value 非法时返回 `ARC_PARAM_INVALID_VALUE`，目标字段保持当前值。
- `arc_param_bit` 使用“解析为 int 后与 0 比较”，不能依赖截断。
- queue 宏支持 `{...}` 整体赋值和 `[index]` 赋值。
- dynamic array 宏支持整体赋值和自动扩展的 `[index]` 赋值。
- assoc 宏支持 `["key"]` string key。
- `arc_param_sub_config(VAR)` 使用成员变量名作为 TC 字段路径，并把剩余子路径转发给该 config。
- `_as(PATH_NAME, HANDLE)` 形式允许 TC 路径名与成员变量名不同。
- sub-config queue 宏解析 index，并把 index 后的子路径转发给对应 config。
- `_new` 形式使用 `new()` 默认构造并自动扩展 queue；非 `_new` 形式要求用户预先构造元素。
- 所有 sub-config 宏在转发前为子 config 派生完整 TC 绑定路径。
- 负数 index 报 error，且不改变集合。
- sub-config queue 缺少子字段路径时报 error。
- 已绑定 nested config 被挂到不同路径时报告 error。

标准写法：

```systemverilog
class tap_config extends arc_param_config;
  delay_config sub_cfg;
  lane_config lanes[$];

  `arc_param_begin
    `arc_param_sub_config(sub_cfg)
    `arc_param_sub_config_queue_new(lanes, lane_config)
  `arc_param_end
endclass
```

对应：

```text
-ARC_PARAM:tch0_tap0_opt.sub_cfg.delay=1
-ARC_PARAM:tch0_tap0_opt.lanes[0].delay=2
```

显式路径别名：

```systemverilog
`arc_param_sub_config_as("sub_cfg", internal_cfg)
`arc_param_sub_config_queue_new_as(
  "lanes",
  internal_lanes,
  lane_config
)
```

不保留旧的 `arc_param_object`、`arc_param_queue_object` 或 `arc_param_queue_object_new` 兼容别名。

enum parser 必须返回解析状态，并通过 output 参数返回结果：

```systemverilog
function bit parse_sat_type(
  string text,
  output sat_type_e parsed
);
  case (text)
    "GLO_L1F": begin
      parsed = GLO_L1F;
      return 1;
    end
    "GLO_L10F": begin
      parsed = GLO_L10F;
      return 1;
    end
    default: return 0;
  endcase
endfunction
```

## 6. TC 语法

格式：

```text
-ARC_PARAM:<param_name>.<field_path>=<value>
```

解析规则：

- 空行忽略。
- `#` 开头的整行注释忽略。
- 非 `-ARC_PARAM:` 行忽略。
- 必须保留 `ARC_PARAM` 前的 `-`。
- 第一个 `.` 前是 `param_name`。
- 第一个 `.` 到第一个 `=` 之间是 `field_path`。
- 第一个 `=` 后是 `value`。
- 三段都要 trim。
- 当前不支持行尾注释。

value 必须支持：

- decimal、signed、underscore。
- `0x`、`0b`、`0o`。
- SV literal，例如 `32'hff`、`'b1010`。
- real、quoted string、bit、enum。
- `{...}` list。

数值解析要求：

- 不依赖一次 `$sscanf` 解析所有 base literal。
- 显式拆分 base/digit，并用 `longint unsigned` 累加。
- unsigned invalid sentinel 使用 `64'hffff_ffff_ffff_ffff`，不用 `-1`。
- 使用显式类型转换避免非预期扩展或截断。

非目标：

- plusarg 自动入口。
- UVM phase 自动集成。
- parse 晚于 phase 或 config 构造时的自动更新。
- 已构造 config 的订阅、回滚或隐式刷新。
- schema/binder/registry。
- 从另一个业务 `arc_param_config` 派生的多层 config 继承。
- 多维数组。
- assoc 整体赋值。
- 完整字符串 escape。
- bit vector 截断诊断。

## 7. 测试与验收顺序

每项先写失败测试，再写最小实现。

`tests/arc_param_pkg` 下的现有测试必须全部按本 spec 重写，不允许通过兼容旧 `arc_param_object`、外部 `cfg.load_arc_param()` 或构造后 parse 的方式保留旧测试。

测试分为两层：

- 场景验收测试必须使用公共 API 完整执行“TC 文件解析 → config 构造 → 构造期加载 → 字段可用”链路。
- codec/tokenizer 等内部算法单元测试可以直接调用 `arc_param_utils`，但只能作为补充，不能代替任何用户 feature 的场景验收。

测试 config 结构：

- 每个 config class 单独放在 `tests/arc_param_pkg/config/*.svh`。
- `arc_param_test_pkg.sv` 只负责 import `arc_param_pkg` 并 include 测试 config。
- usage test import `arc_param_test_pkg`，不得在 test module 内临时定义简化 config class。
- 场景输入统一放在 `tests/arc_param_pkg/tc/*.tc`。

场景验收测试禁止：

- 在 config `new()` 之后才 parse。
- 调用旧的 `cfg.load_arc_param()`。
- 直接调用 `apply_arc_param()` 代替 DB 加载。
- 直接调用 utils 代替字段宏注入。
- 继承旧的 `arc_param_object`。

### T0：package 与标准用户流程

- package 可由 VCS 编译。
- `import arc_param_pkg::*` 可用。
- 测试 config 声明为 `extends arc_param_config`。
- testcase 先解析 TC，再调用 `new("tch0_tap0_opt")`。
- config 的 `new()` 末尾调用 `ARC_PARAM_DB.load_tc_param(this)`。
- 调用方不调用 `cfg.load_arc_param()`。
- config 创建完成时 TC 参数已经生效。
- TC 中没有对应 `param_path` 的 config 保留默认值。
- 从实际 `.tc` 文件解析，不用直接 utils 调用代替。

### T1：codec

覆盖：

- `123`、`-123`、`1_000`。
- `0x10`、`0b1010`、`0o17`。
- `32'hff`、`'b1010`、`'o17`、`'d10`。
- int、longint、longint unsigned。
- real `0.75`。
- string `"fast"` 转成 `fast`。

### T2：tokenizer/list

覆盖：

- `{1,2,3}` 去除一层 brace。
- 顶层逗号拆分。
- `"a,b",c` 不拆字符串内逗号。
- `{1,2},3` 不拆内层 brace 中的逗号。
- `{}` 是合法空列表。

### T3：实例身份与字段注入

`tc/real_usage.tc` 至少包含：

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
-ARC_PARAM:tch1_tap0_opt.run_num=2
```

验收：

- 两个相同 config 类型、不同 `param_path` 的实例获得各自参数。
- 两个不同 handle、相同 `param_path` 的实例获得相同参数。
- scalar、enum、queue 和 nested config 注入正确。
- 用户不手写 `apply_arc_param()`。
- unknown field 只报告一次，不 fatal。

### T4：array/queue 整体与索引赋值

- queue int/real/string 支持整体赋值。
- dynamic array int/real/string 支持整体赋值。
- queue 整体赋值先清空再重建。
- dynamic array 整体赋值重新 `new[size]`。
- string list 中的逗号不被误拆。

### T5：assoc 与 sub-config queue

- assoc int/string/real 的 string key 可用。
- `arc_param_sub_config_queue_new` 自动创建并扩展 queue。
- `arc_param_sub_config_queue` 支持预先创建的 config。
- sub-config queue 负数 index 报 error。
- sub-config queue 缺少子字段路径报 error。
- nested config 获得完整绑定路径，并能独立重放。

### T6：诊断与幂等性

- total/used/unused/unknown/warning/error 计数正确。
- unknown、invalid 和 unused 互斥，同一个 item 不重复归类或重复报告。
- config 路径匹配但字段未声明的 item 只计 unknown，不计 unused。
- 从未匹配任何 config 路径的 item 才计 unused。
- 非 strict 模式 unknown/unused 不增加 error。
- strict 模式按定义升级 error。
- strict unknown/unused 用 error 替代 warning，不进行双计数。
- 重复 `load_tc_param()` 必须重新赋值，但不重复增加 used、unknown、error 或 warning。
- 重复 `check_unused()` 不重复增加 unused。
- rand 字段在 `randomize()` 后通过 `post_randomize()` 重放 TC 值。
- TC 值覆盖随机结果，最终统计计数保持不变。
- 不覆盖 callback 的 config 继承基类 `post_randomize()` 后自动重放。
- 覆盖 callback 的 config 在末尾调用 `super.post_randomize()` 后自动重放。
- common TC 与 testcase TC 中的重复完整键按后解析覆盖，并只报告一次 duplicate warning。

### T7：bad input

- bad line 报 error 且不崩溃。
- 普通 queue 和 sub-config queue 的负数 index 报 error。
- 非法 index 不改变目标集合。
- null config 传给 `load_tc_param()` 报 error。
- 空 `param_path` 调用 `load_tc_param()` 正常 no-op。
- nested config 获得父宏派生的完整路径后可以独立重放。
- 同一 config handle 尝试绑定两个路径时报告 error。
- 两个不同 config handle 使用同一路径时都能正确加载，且统计不随实例数重复增加。
- 首次绑定后的 sub-config queue 拓扑保持稳定。
- 非法 int/real/base literal/enum 不修改字段当前值。
- 非法 value 返回 `ARC_PARAM_INVALID_VALUE`，不同时报告 unknown 或 unused。
- 重复重放非法 item 时只报告一次 error。
- 同键的后续合法 item仍能正常覆盖。

### 7.1 必须存在的 test top

```text
test_arc_param_real_usage.sv
test_arc_param_collections_usage.sv
test_arc_param_override_usage.sv
test_arc_param_randomize_usage.sv
test_arc_param_binding_usage.sv
test_arc_param_diagnostics_usage.sv
test_arc_param_invalid_usage.sv
test_arc_param_codec_unit.sv
test_arc_param_tokenizer_unit.sv
```

职责：

- `real_usage`：parse 早于 new、两个顶层实例、构造完成立即生效。
- `collections_usage`：queue、array、assoc、single nested、自动创建 sub-config queue。
- `override_usage`：common TC 与 override TC，后解析覆盖并产生一次 duplicate warning。
- `randomize_usage`：构造期加载、基类自动 post-randomize、业务 callback override。
- `binding_usage`：nested 完整路径、子节点独立重放、稳定路径、同路径多 handle。
- `diagnostics_usage`：unknown、unused、strict、重复重放统计幂等。
- `invalid_usage`：非法 scalar/enum/index、保留当前值、单次 error、后续合法覆盖。
- `_unit`：仅补充 codec/tokenizer 的内部算法边界。

## 8. VCS 回归

在 `run/Makefile` 中集成 `arc_param_pkg` 和 `arc_param_regression`：

- 从仓库根目录运行 `make -C run arc_param_regression SIM=vcs`。
- 使用 `+incdir+$(ROOT_DIR)/src/arc_param_pkg`。
- 编译入口是 `src/arc_param_pkg/arc_param_pkg.sv`。
- usage test 在 test top 之前编译 `tests/arc_param_pkg/arc_param_test_pkg.sv`。
- 编译选项包含 `+incdir+$(ROOT_DIR)/tests/arc_param_pkg`。
- 逐个运行 `tests/arc_param_pkg/test_arc_param_*.sv`。
- T0–T7 全部通过后打印 `ARC_PARAM VCS regression PASS`。
- 不以 Verilator 结果代替 VCS 验收。

## 9. 总验收 checklist

使用模型：

- [ ] 用户 config 继承 `arc_param_config`。
- [ ] 顶层 `param_path` 由 config 构造函数显式传入。
- [ ] nested `param_path` 由父节点 sub-config 宏自动派生。
- [ ] testcase 在创建 config 前解析 TC。
- [ ] 所有 parse 动作早于所有 phase 和所有 config `new()`。
- [ ] config 在自己的 `new()` 末尾调用 `ARC_PARAM_DB.load_tc_param(this)`。
- [ ] config 创建完成后参数已生效。
- [ ] 外部不再调用 `cfg.load_arc_param()`。
- [ ] 同类型多实例按 `param_path` 正确隔离。
- [ ] 任意已绑定 nested config 可以独立重放参数。
- [ ] nested config 的首次路径绑定不可变。
- [ ] 同一 config handle 不能同时绑定多个参数树位置。
- [ ] 不同 config handle 可以共享同一 TC 绑定路径。
- [ ] `load_tc_param()` 可用于构造期加载和 `post_randomize()` 重放。
- [ ] TC 值最终覆盖随机结果，重复重放不重复统计或刷诊断。

结构：

- [ ] `src/arc_param_pkg/README.md` 存在并包含真实使用指南。
- [ ] 一个 class 一个文件。
- [ ] 仅保留一个 `arc_param_utils.svh`。
- [ ] 工具函数全部位于 `arc_param_utils` class 内。
- [ ] 不存在 `automatic function`；工具函数均为 `arc_param_utils` 内的 `static function`。
- [ ] package 文件只做 include、前向声明和全局 DB。

API：

- [ ] `arc_param_config`、`arc_param_db`、`ARC_PARAM_DB` 存在。
- [ ] `arc_param_item` 使用字段名 `param_name`。
- [ ] `apply_arc_param()` 是普通 virtual，默认返回 `ARC_PARAM_NOT_MATCHED`。
- [ ] apply 结果能区分 not matched、applied 和 invalid value。
- [ ] `ARC_PARAM_DB.load_tc_param(arc_param_config)` 是唯一构造期加载入口。
- [ ] `arc_param_config::post_randomize()` 自动重放 TC 参数。
- [ ] `arc_param_db::get()` 返回唯一实例。
- [ ] 只有小写字段宏。

功能：

- [ ] 支持 scalar、queue、array、assoc、nested config、sub-config queue。
- [ ] 支持规定的 numeric/string/list codec。
- [ ] unknown、unused、bad line、negative index 有诊断和计数。
- [ ] invalid value 保留字段当前值，并且单次诊断。
- [ ] unknown、invalid、unused 对同一个 item 互斥。
- [ ] strict unknown/unused 可升级为 error。
- [ ] 重复 load/check 不重复报告。

验证：

- [ ] `tests/arc_param_pkg` 下所有旧测试均已按新模型重写。
- [ ] T0–T7 的每个用户 feature 都由公共 API 场景测试覆盖。
- [ ] codec/tokenizer 内部单元测试只作为补充。
- [ ] VCS 一键回归通过。
- [ ] 最终输出 `ARC_PARAM VCS regression PASS`。

## 10. 禁止回退项

- 不恢复外部 `cfg.load_arc_param()` 使用流程。
- 不在 `arc_param_config::new()` 中隐式加载。
- 不为晚解析维护 config handle registry 或自动更新机制。
- 不因 item 已标记 used 而跳过重复赋值。
- 不由 ARC_PARAM 隐式修改字段 `rand_mode`。
- 不以类名代替实例 `param_path`。
- 不在 v1 中实现已绑定 config 节点的移动、共享或动态路径追踪。
- 不使用含义模糊的 `arc_param_object` / `obj_name` 作为主模型名称。
- 不保留旧 `arc_param_object` / `arc_param_queue_object*` 宏兼容别名。
- 不支持业务 config 的多层继承；复用配置结构时使用组合。
- 不使用 pure virtual `apply_arc_param()`。
- 不在 value 解析失败后用 sentinel 或默认 enum 覆盖字段。
- 不在 class 外定义工具函数。
- 不拆分出多个 utils 文件。
- 不恢复大写字段宏别名。
- 不用 Verilator 代替 VCS。
- 不扩展 plusarg、schema、registry 或 UVM phase 集成，除非单独立项。

## 11. 给实现者的执行提示

1. 先把标准用户 demo 写成 VCS 测试，再修改实现。
2. 将旧 `arc_param_object` 模型迁移为 `arc_param_config`。
3. 将 item 的 `obj_name` 迁移为 `param_name`。
4. 将 DB 的 `load()` 迁移为 `load_tc_param(arc_param_config)`。
5. 删除 config 对象上的 `load_arc_param()`。
6. 更新所有测试，使加载发生在 config 自己的 `new()` 末尾。
7. 逐项完成 T0–T7，再跑完整 VCS 回归。

## 12. `arc_param_pkg` README 必须包含的内容

`src/arc_param_pkg/README.md` 至少包含：

1. 在所有 phase 和 config 构造前解析 TC 的启动顺序。
2. 一个直接继承 `arc_param_config` 的完整 config 示例。
3. 构造函数末尾调用 `ARC_PARAM_DB.load_tc_param(this)`。
4. scalar、enum、queue、array 和 assoc 字段宏示例。
5. single nested config 与 sub-config queue 示例。
6. 顶层路径显式传入、nested 完整路径由父宏自动派生。
7. 空绑定路径的合法 no-op 行为。
8. 同一 config 类型独立使用与 nested 使用的示例。
9. `randomize()` 后由基类 `post_randomize()` 自动重放。
10. 业务 override `post_randomize()` 时最后调用 `super.post_randomize()`。
11. TC 值可能覆盖 constraint 求解结果的注意事项。
12. stable parameter tree、不可改绑和 handle 不可多位置共享的约束。
13. 重复键后解析覆盖先解析、duplicate warning 的规则。
14. invalid value 保留当前值并只报告一次 error。
15. `check_unused()`、`summary()` 和 strict 模式的使用方式。
