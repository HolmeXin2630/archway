// =============================================================================
// Test: crg_pkg clock facade behavior
// =============================================================================

module test_crg_pkg;

  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import crg_pkg::*;
  import archway_pkg::*;

  arc_clk_if u_simple_clk_if();
  arc_clk_if u_advanced_clk_if();
  arc_clk_if u_gated_clk_if();
  arc_clk_if u_jitter_clk_if();
  arc_rst_if u_default_rst_if();
  arc_rst_if u_advanced_rst_if();
  arc_rst_if u_manual_rst_if();

  logic external_clk_en = 1'b1;
  assign u_gated_clk_if.clk_en = external_clk_en;

  realtime advanced_first_clk_rise = -1.0;
  realtime advanced_rst_assert_time = -1.0;
  bit manual_reset_cancellation_checked;

  always @(posedge u_advanced_clk_if.clk) begin
    if (advanced_first_clk_rise < 0.0)
      advanced_first_clk_rise = $realtime;
  end

  always @(posedge u_advanced_rst_if.rst) begin
    if (advanced_rst_assert_time < 0.0)
      advanced_rst_assert_time = $realtime;
  end

  class test_crg_pkg extends uvm_test;

    `uvm_component_utils(test_crg_pkg)

    archway_env m_env0;
    archway_env m_env1;

    function new(string name = "test_crg_pkg", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_env0 = new("env0", this);
      m_env1 = new("env1", this);
    endfunction

    task automatic measure_period_and_high_time(
      input virtual arc_clk_if vif,
      output realtime period,
      output realtime high_time
    );
      realtime rising_edge;
      realtime falling_edge;

      @(posedge vif.clk);
      rising_edge = $realtime;
      @(negedge vif.clk);
      falling_edge = $realtime;
      @(posedge vif.clk);

      period    = $realtime - rising_edge;
      high_time = falling_edge - rising_edge;
    endtask

    task automatic expect_approximately(
      input string label,
      input realtime actual,
      input realtime expected,
      input realtime tolerance
    );
      assert (actual >= expected - tolerance && actual <= expected + tolerance)
        else $fatal(1,
          "%s: expected %.6fns, measured %.6fns",
          label, expected, actual);
    endtask

    virtual task main_phase(uvm_phase phase);
      arc_clk_source simple_source;
      arc_clk_source advanced_source;
      arc_clk_source gated_source;
      arc_clk_source jitter_source;
      realtime period;
      realtime high_time;
      realtime jitter_min_period;
      realtime jitter_max_period;
      string clk_names[$];
      string rst_names[$];
      uvm_component managers[$];

      phase.raise_objection(this);

      // Simple facade registration keeps the 50.5MHz default-duty path concise.
      assert (ARC_CLKS::has_clk("soc.simple_clk"))
        else $fatal(1, "Simple clock was not discoverable");
      simple_source = ARC_CLKS::clk("soc.simple_clk");
      assert (simple_source != null)
        else $fatal(1, "Simple clock source was null");
      ARC_CLKS::get_clk_names(clk_names);
      assert (clk_names.size() == 4)
        else $fatal(1, "Clock registry enumeration omitted a source");
      assert (clk_names[0] == "soc.advanced_clk" &&
              clk_names[1] == "soc.gated_clk" &&
              clk_names[2] == "soc.jitter_clk" &&
              clk_names[3] == "soc.simple_clk")
        else $fatal(1, "Clock registry enumeration was not deterministic");
      ARC_RSTS::get_rst_names(rst_names);
      assert (rst_names.size() == 3)
        else $fatal(1, "Reset registry enumeration omitted a source");
      assert (rst_names[0] == "soc.advanced_rst" &&
              rst_names[1] == "soc.default_rst" &&
              rst_names[2] == "soc.manual_rst")
        else $fatal(1, "Reset registry enumeration was not deterministic");

      // Two Archway environments must share one simulation-wide manager.
      uvm_root::get().find_all("*.crg_manager", managers);
      assert (managers.size() == 1)
        else $fatal(1,
          "Expected one simulation-wide CRG manager, found %0d",
          managers.size());

      // Complex registration applies startup delay and non-50-percent duty cycle.
      advanced_source = ARC_CLKS::clk("soc.advanced_clk");
      assert (advanced_first_clk_rise >= 20.0)
        else $fatal(1,
          "Advanced clock rose before its 20ns start_delay: %.6fns",
          advanced_first_clk_rise);
      measure_period_and_high_time(advanced_source.vif, period, high_time);
      expect_approximately("advanced clock period", period, 20.0, 0.002);
      expect_approximately("advanced clock high time", high_time, 5.0, 0.002);

      measure_period_and_high_time(simple_source.vif, period, high_time);
      expect_approximately("simple clock period", period, 1000.0 / 50.5, 0.002);
      expect_approximately("simple clock high time", high_time, 500.0 / 50.5, 0.002);

      // PPM cycle jitter changes complete periods while preserving legal bounds.
      jitter_source = ARC_CLKS::clk("soc.jitter_clk");
      jitter_min_period = 1.0e9;
      jitter_max_period = 0.0;
      repeat (8) begin
        measure_period_and_high_time(jitter_source.vif, period, high_time);
        assert (period >= 9.498 && period <= 10.502)
          else $fatal(1, "Jittered period %.6fns exceeded +/-50,000ppm", period);
        assert (high_time > 0.0 && high_time < period)
          else $fatal(1, "Jittered clock emitted an invalid pulse");
        if (period < jitter_min_period) jitter_min_period = period;
        if (period > jitter_max_period) jitter_max_period = period;
      end
      assert (jitter_max_period > jitter_min_period)
        else $fatal(1, "Representable jitter did not vary the clock period");

      // External wired-AND control and facade control both gate only the output.
      gated_source = ARC_CLKS::clk("soc.gated_clk");
      @(posedge gated_source.vif.clk);
      external_clk_en = 1'b0;
      @(negedge gated_source.vif.clk);
      repeat (2) @(posedge gated_source.vif.free_run_clk);
      assert (gated_source.vif.clk === 1'b0)
        else $fatal(1, "External gate did not hold output clock low");

      external_clk_en = 1'b1;
      @(posedge gated_source.vif.clk);
      ARC_CLKS::disable_clk("soc.gated_clk");
      assert (gated_source.vif.clk === 1'b0)
        else $fatal(1, "disable() returned before output clock was low");
      repeat (2) @(posedge gated_source.vif.free_run_clk);
      assert (gated_source.vif.clk === 1'b0)
        else $fatal(1, "Disabled clock emitted an output edge");

      ARC_CLKS::enable_clk("soc.gated_clk");
      @(posedge gated_source.vif.clk);
      ARC_CLKS::change_freq("soc.gated_clk", "50MHz");
      measure_period_and_high_time(gated_source.vif, period, high_time);
      expect_approximately("changed clock period", period, 20.0, 0.002);

      ARC_CLKS::change_duty_cycle("soc.gated_clk", 25.0);
      measure_period_and_high_time(gated_source.vif, period, high_time);
      expect_approximately("changed duty high time", high_time, 5.0, 0.002);

      ARC_CLKS::change_jitter("soc.gated_clk", 10_000.0);
      measure_period_and_high_time(gated_source.vif, period, high_time);
      assert (period >= 19.798 && period <= 20.202)
        else $fatal(1, "Runtime jitter change was not applied");

      ARC_CLKS::change_jitter("soc.gated_clk", 0.0);
      fork
        ARC_CLKS::change_freq("soc.gated_clk", "100MHz");
        ARC_CLKS::change_duty_cycle("soc.gated_clk", 40.0);
      join
      measure_period_and_high_time(gated_source.vif, period, high_time);
      expect_approximately("concurrent timing change period", period, 10.0, 0.002);
      expect_approximately("concurrent timing change high time", high_time, 4.0, 0.002);

      ARC_RSTS::assert_rst("soc.advanced_rst");
      assert (u_advanced_rst_if.rst === 1'b1)
        else $fatal(1, "Manual assert did not drive active-high reset");
      #37ns;
      ARC_RSTS::deassert_rst("soc.advanced_rst");
      assert (u_advanced_rst_if.rst === 1'b0)
        else $fatal(1, "Manual deassert did not release active-high reset");
      ARC_RSTS::wait_all_deasserted();

      $display("PASS: clock and reset CRG public behavior");
      phase.drop_objection(this);
    endtask

    virtual task reset_phase(uvm_phase phase);
      phase.raise_objection(this);
      fork
        begin
          #50ns;
          ARC_RSTS::deassert_rst("soc.manual_rst");
          #150ns;
          assert (u_manual_rst_if.rst === 1'b0)
            else $fatal(1, "Manual reset takeover did not cancel scheduled assert");
          manual_reset_cancellation_checked = 1;
        end
      join_none
      ARC_RSTS::wait_all_deasserted();
      wait (manual_reset_cancellation_checked);

      assert ($realtime >= 100.0)
        else $fatal(1, "Reset readiness returned before default deassert delay");
      assert (u_default_rst_if.rst === 1'b1)
        else $fatal(1, "Default active-low reset was not deasserted");
      assert (u_advanced_rst_if.rst === 1'b0)
        else $fatal(1, "Advanced active-high reset was not deasserted");
      assert (advanced_rst_assert_time >= 20.0)
        else $fatal(1, "Advanced reset did not assert at its scheduled time");

      phase.drop_objection(this);
    endtask

  endclass

  initial begin
    arc_clk_source advanced_source;
    arc_clk_source gated_source;
    arc_clk_source jitter_source;
    arc_rst_source advanced_rst_source;
    arc_rst_source manual_rst_source;

    ARC_CLKS::add_new_clk("soc.simple_clk", u_simple_clk_if, "50.5M");

    advanced_source = new("soc.advanced_clk");
    advanced_source.vif              = u_advanced_clk_if;
    advanced_source.freq             = "50MHz";
    advanced_source.duty_cycle_pct   = 25.0;
    advanced_source.cycle_jitter_ppm = 0.0;
    advanced_source.start_delay      = "20ns";
    advanced_source.random_seed      = 32'hA11CE;
    ARC_CLKS::add_clk_source("soc.advanced_clk", advanced_source);

    gated_source = new("soc.gated_clk");
    gated_source.vif         = u_gated_clk_if;
    gated_source.freq        = "100MHz";
    gated_source.start_delay = "0ns";
    ARC_CLKS::add_clk_source("soc.gated_clk", gated_source);

    jitter_source = new("soc.jitter_clk");
    jitter_source.vif              = u_jitter_clk_if;
    jitter_source.freq             = "100MHz";
    jitter_source.duty_cycle_pct   = 50.0;
    jitter_source.cycle_jitter_ppm = 50_000.0;
    jitter_source.start_delay      = "0ns";
    jitter_source.random_seed      = 32'hC10C;
    ARC_CLKS::add_clk_source("soc.jitter_clk", jitter_source);

    ARC_RSTS::add_new_rst("soc.default_rst", u_default_rst_if, "100ns");

    advanced_rst_source = new("soc.advanced_rst");
    advanced_rst_source.vif              = u_advanced_rst_if;
    advanced_rst_source.active_high      = 1'b1;
    advanced_rst_source.initial_asserted = 1'b0;
    advanced_rst_source.assert_delay     = "20ns";
    advanced_rst_source.deassert_delay   = "70ns";
    ARC_RSTS::add_rst_source("soc.advanced_rst", advanced_rst_source);

    manual_rst_source = new("soc.manual_rst");
    manual_rst_source.vif              = u_manual_rst_if;
    manual_rst_source.active_high      = 1'b1;
    manual_rst_source.initial_asserted = 1'b0;
    manual_rst_source.assert_delay     = "150ns";
    manual_rst_source.deassert_delay   = "300ns";
    ARC_RSTS::add_rst_source("soc.manual_rst", manual_rst_source);

    run_test("test_crg_pkg");
  end

endmodule
