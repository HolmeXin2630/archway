# CRG package

`crg_pkg` provides simulation-only named clock and reset sources.  Register all
sources from a testbench `initial` block before UVM runtime begins; registries
lock as soon as the shared `arc_crg_manager` starts them in `run_phase`.

## Clocks

The concise registration API is:

```systemverilog
arc_clk_if u_clk_if();
ARC_CLKS::add_new_clk("soc.core_clk", u_clk_if, "50.5MHz");
```

For advanced setup, configure an `arc_clk_source` before registration:

```systemverilog
arc_clk_source core_clk;
core_clk = new("soc.core_clk");
core_clk.vif              = u_clk_if;
core_clk.freq             = "50.5MHz";
core_clk.duty_cycle_pct   = 45.0;
core_clk.cycle_jitter_ppm = 2_000.0;
core_clk.start_delay      = "20ns"; // or "random" (the default)
core_clk.random_seed      = 1234;   // optional reproducibility seed
ARC_CLKS::add_clk_source("soc.core_clk", core_clk);
```

`free_run_clk` always runs. `clk` is gated through the wired-AND `clk_en`, so
an external continuous assignment and `ARC_CLKS::enable_clk()` combine safely.
`disable_clk()` returns only after `clk` is low. Runtime timing calls
`change_freq`, `change_duty_cycle`, and `change_jitter` take effect at the
next complete-cycle boundary and return after adoption. `disable` is a
SystemVerilog keyword, so the public operation is named `disable_clk`.

## Resets

The simple active-low, initially asserted reset path is:

```systemverilog
arc_rst_if u_rst_if();
ARC_RSTS::add_new_rst("soc.por_n", u_rst_if, "300ns");
```

An `arc_rst_source` additionally accepts `active_high`, `initial_asserted`,
`assert_delay`, and `deassert_delay`. Both times are relative to manager
runtime start; an initially inactive reset must assert strictly before it
deasserts. Manual control is immediate:

```systemverilog
ARC_RSTS::assert_rst("soc.por_n");
#100ns;
ARC_RSTS::deassert_rst("soc.por_n");
```

The first manual operation takes ownership, cancelling remaining startup
events. Tests own their phase objection and may wait for startup readiness;
the wait does not return merely because a delayed initially-inactive reset is
currently low—it waits until every startup schedule has completed (or has been
manually taken over) and every reset is inactive:

```systemverilog
ARC_RSTS::wait_all_deasserted();
```

Clocks and resets are independent: reset timing never waits for a clock edge.

## Precision and non-goals

Default precision is `1ns/1ps`. Compile with `+define+ARC_CRG_HIGH_PRECISION`
for `1ps/1fs`; the dedicated `test_crg_pkg_high_precision` target exercises
that mode. CRG deliberately has no YAML configuration, dynamic source
insertion, or manager-owned phase objections.
