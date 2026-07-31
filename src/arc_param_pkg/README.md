# arc_param_pkg 使用指南

`arc_param_pkg` 将 `.tc` 文件中的参数绑定到 SystemVerilog config。config 通过继承 `arc_param_config` 和字段宏明确声明可由 testcase 覆盖的字段。

## 当前进展

ARC_PARAM v1 已实现并完成 VCS 验证：

- 已提供 scalar、queue、dynamic array、assoc、nested config 和 sub-config queue 参数注入。
- 已提供构造期加载、`post_randomize()` 自动重放、稳定路径绑定、重复键覆盖及诊断/strict 模式。
- 真实场景测试覆盖标准使用、集合、TC 覆盖、randomize、路径绑定、诊断和非法输入；codec/tokenizer 保留独立单元测试。
- 在仓库根目录执行下列命令可运行全部九个 test top，成功时打印 `ARC_PARAM VCS regression PASS`：

  ```text
  make -C run arc_param_regression SIM=vcs
  ```

## 启动顺序

环境必须在所有 phase 和所有 config 构造之前解析 TC：

```systemverilog
import arc_param_pkg::*;

initial begin
  ARC_PARAM_DB.clear();
  ARC_PARAM_DB.parse_file("case.tc");

  // parse 完成后才能创建 config。
  cfg = new("tch0_tap0_opt");
end
```

ARC_PARAM 不维护已构造对象的订阅表，也不支持晚解析后的自动更新。

TC 格式：

```text
-ARC_PARAM:<param_name>.<field_path>=<value>
```

例如：

```text
-ARC_PARAM:tch0_tap0_opt.run_num=1
-ARC_PARAM:tch0_tap0_opt.mode="fast"
-ARC_PARAM:tch0_tap0_opt.sub_cfg.delay=5
-ARC_PARAM:tch0_tap0_opt.lanes[0].delay=7
```

## 定义 config

业务 config 必须直接继承 `arc_param_config`：

```systemverilog
class tap_config extends arc_param_config;
  rand int run_num = 0;
  string mode = "normal";

  `arc_param_begin
    `arc_param_int(run_num)
    `arc_param_string(mode)
  `arc_param_end

  function new(string param_path = "");
    super.new(param_path);

    // 默认值、子 config 和集合必须先完成初始化。
    ...

    // 构造函数最后加载 TC 参数。
    ARC_PARAM_DB.load_tc_param(this);
  endfunction
endclass
```

调用：

```systemverilog
tap_config cfg;

ARC_PARAM_DB.clear();
ARC_PARAM_DB.parse_file("case.tc");
cfg = new("tch0_tap0_opt");

// new 返回时 TC 参数已经生效。
assert(cfg.run_num == 1);
assert(cfg.mode == "fast");
```

v1 不支持从另一个业务 config 继续派生：

```systemverilog
// 不支持
class derived_config extends tap_config;
endclass
```

需要复用配置结构时使用成员组合和 nested config。

## 字段宏

标量与 enum：

```systemverilog
typedef enum {GLO_L1F, GLO_L10F} sat_type_e;

int run_num;
bit enabled;
string mode;
real ratio;
sat_type_e sat_type;

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

`arc_param_begin
  `arc_param_int(run_num)
  `arc_param_bit(enabled)
  `arc_param_string(mode)
  `arc_param_real(ratio)
  `arc_param_enum(sat_type, parse_sat_type)
`arc_param_end
```

集合：

```systemverilog
int int_q[$];
real real_q[$];
string string_q[$];
int int_a[];
real real_a[];
string string_a[];
int weight[string];
real ratio_by_name[string];
string alias_name[string];

`arc_param_begin
  `arc_param_queue_int(int_q)
  `arc_param_queue_real(real_q)
  `arc_param_queue_string(string_q)
  `arc_param_array_int(int_a)
  `arc_param_array_real(real_a)
  `arc_param_array_string(string_a)
  `arc_param_assoc_int(weight)
  `arc_param_assoc_real(ratio_by_name)
  `arc_param_assoc_string(alias_name)
`arc_param_end
```

对应 TC：

```text
-ARC_PARAM:cfg.int_q={1,2,3}
-ARC_PARAM:cfg.int_q[1]=8
-ARC_PARAM:cfg.int_a={4,5}
-ARC_PARAM:cfg.weight["tap0"]=7
```

## Nested config

同一个 config 类型既可以独立绑定，也可以作为 nested 节点。

子 config：

```systemverilog
class delay_config extends arc_param_config;
  rand int delay = 0;

  `arc_param_begin
    `arc_param_int(delay)
  `arc_param_end

  function new(string param_path = "");
    super.new(param_path);
    ARC_PARAM_DB.load_tc_param(this);
  endfunction
endclass
```

单个 nested config：

```systemverilog
class tap_config extends arc_param_config;
  delay_config sub_cfg;

  `arc_param_begin
    `arc_param_sub_config(sub_cfg)
  `arc_param_end

  function new(string param_path = "");
    super.new(param_path);
    sub_cfg = new();
    ARC_PARAM_DB.load_tc_param(this);
  endfunction
endclass
```

对应：

```text
-ARC_PARAM:tch0_tap0_opt.sub_cfg.delay=5
```

sub-config queue：

```systemverilog
delay_config lanes[$];

`arc_param_begin
  `arc_param_sub_config_queue_new(lanes, delay_config)
`arc_param_end
```

对应：

```text
-ARC_PARAM:tch0_tap0_opt.lanes[0].delay=7
-ARC_PARAM:tch0_tap0_opt.lanes[2].delay=9
```

`_new` 宏使用 `new()` 默认构造并自动扩展 queue。需要自行构造元素时使用：

```systemverilog
`arc_param_sub_config_queue(lanes)
```

TC 路径名与成员名不同时使用 `_as`：

```systemverilog
`arc_param_sub_config_as("sub_cfg", internal_cfg)
`arc_param_sub_config_queue_new_as(
  "lanes",
  internal_lanes,
  delay_config
)
```

父宏会自动为 nested 节点派生完整绑定路径：

```text
tch0_tap0_opt
tch0_tap0_opt.sub_cfg
tch0_tap0_opt.lanes[0]
```

空绑定路径是合法状态。尚未挂到父节点的 nested config 调用 `load_tc_param()` 时正常 no-op；绑定完成后，该节点可以独立重放自己的 TC 参数。

## Randomize 后重放

`arc_param_config` 基类实现 SystemVerilog 内建 `post_randomize()` callback，并在其中调用：

```systemverilog
ARC_PARAM_DB.load_tc_param(this);
```

因此：

```systemverilog
cfg.randomize();
```

结束后，TC 中明确给出的字段会覆盖本次随机结果。重复重放会重新赋值，但不会重复增加 used、unknown、warning 或 error 计数。

业务 config 覆盖 `post_randomize()` 时，必须最后调用基类：

```systemverilog
function void post_randomize();
  // 业务处理
  ...

  // 必须最后调用，保证 TC 最终优先。
  super.post_randomize();
endfunction
```

注意：post-randomize 覆盖可能使最终字段值不满足刚完成求解的 constraint。ARC_PARAM 不自动调用 `rand_mode(0)`；使用方负责保证 TC 值与 constraint 的业务一致性。

## 稳定参数树

config 节点第一次获得非空绑定路径后：

- 再次绑定相同路径是合法 no-op。
- 绑定到不同路径时报 error。
- 同一个 config handle 不能同时挂在两个位置。
- 不同 handle 可以共享同一个绑定路径并获得相同参数。
- 已绑定的 sub-config queue 元素不能移动、交换或删除。
- v1 不跟踪 rand queue 引起的 config 拓扑变化。

## 重复参数

可以依次解析公共 TC 和用例 TC：

```systemverilog
ARC_PARAM_DB.parse_file("common.tc");
ARC_PARAM_DB.parse_file("special_case.tc");
```

同一完整键重复出现时：

- 按解析顺序应用。
- 后解析的值最终生效。
- 报告一次 duplicate warning，并显示新旧文件和行号。
- 每次重放仍按相同顺序赋值。

## 非法值与诊断

字段赋值结果分为：

```systemverilog
typedef enum {
  ARC_PARAM_NOT_MATCHED,
  ARC_PARAM_APPLIED,
  ARC_PARAM_INVALID_VALUE
} arc_param_apply_result_e;
```

非法 int、real、base literal 或 enum：

- 报告一次 error。
- 保留字段当前值。
- 不同时报告 unknown 或 unused。
- 重复重放时重新尝试，但不重复刷 error。
- 同键后续存在合法值时，合法值仍正常生效。

unknown、invalid 和 unused 互斥：

- unknown：绑定路径存在，但没有字段宏识别相对路径。
- invalid：字段存在，但输入不能应用。
- unused：没有任何已构造 config 的绑定路径匹配该 item。

所有 config 创建完成后：

```systemverilog
ARC_PARAM_DB.check_unused();
ARC_PARAM_DB.summary();
```

strict 模式：

```systemverilog
ARC_PARAM_DB.set_strict(
  .strict_unknown_en(1),
  .strict_unused_en(1)
);
```

strict unknown/unused 使用 error 替代 warning，不进行 warning 与 error 双计数。duplicate key 始终保持 warning。

## 验证

使用 VCS 运行完整回归：

```text
make -C run arc_param_regression SIM=vcs
```

所有用户 feature 必须由真实 `.tc` 文件、DB 解析、config 构造和宏赋值的完整链路验证。直接调用 utils 的 codec/tokenizer 测试只作为内部算法补充。
